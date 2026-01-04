import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../accounts/data/repositories/account_repository.dart';
import '../../domain/models/transaction_model.dart';

const _uuid = Uuid();

/// Repositorio de transacciones con soporte offline-first
class TransactionRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;
  final AccountRepository _accountRepository;

  TransactionRepository({
    AppDatabase? database,
    SupabaseClient? supabaseClient,
    AccountRepository? accountRepository,
  })  : _db = database ?? AppDatabase(),
        _supabase = supabaseClient ?? SupabaseClientProvider.clientOrNull,
        _accountRepository = accountRepository ?? AccountRepository();

  /// Verifica si Supabase está disponible
  bool get _isOnline => _supabase != null && SupabaseClientProvider.isInitialized;

  // ==================== OPERACIONES LOCALES ====================

  /// Obtener transacciones del usuario ordenadas por fecha
  Stream<List<TransactionModel>> watchTransactions(
    String userId, {
    int limit = 50,
    DateTime? fromDate,
    DateTime? toDate,
    String? accountId,
    int? categoryId,
    TransactionType? type,
  }) {
    var query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      leftOuterJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
    ]);

    query = query
      ..where(_db.transactions.userId.equals(userId));

    if (fromDate != null) {
      query = query..where(_db.transactions.date.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query = query..where(_db.transactions.date.isSmallerOrEqualValue(toDate));
    }
    if (accountId != null) {
      query = query..where(_db.transactions.accountId.equals(accountId));
    }
    if (categoryId != null) {
      query = query..where(_db.transactions.categoryId.equals(categoryId));
    }
    if (type != null) {
      query = query..where(_db.transactions.type.equals(type.name));
    }

    query = query
      ..orderBy([OrderingTerm.desc(_db.transactions.date)])
      ..limit(limit);

    return query.watch().map((rows) {
      return rows.map((row) {
        final tx = row.readTable(_db.transactions);
        final cat = row.readTableOrNull(_db.categories);
        final acc = row.readTableOrNull(_db.accounts);
        return _transactionFromRow(tx, category: cat, account: acc);
      }).toList();
    });
  }

  /// Obtener transacciones recientes
  Stream<List<TransactionModel>> watchRecentTransactions(String userId, {int limit = 10}) {
    return watchTransactions(userId, limit: limit);
  }

  /// Obtener una transaccion por ID
  Future<TransactionModel?> getTransactionById(String id) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      leftOuterJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
    ])
      ..where(_db.transactions.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final tx = result.readTable(_db.transactions);
    final cat = result.readTableOrNull(_db.categories);
    final acc = result.readTableOrNull(_db.accounts);
    return _transactionFromRow(tx, category: cat, account: acc);
  }

  /// Crear transaccion
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final companion = TransactionsCompanion.insert(
      id: transaction.id,
      userId: transaction.userId,
      accountId: transaction.accountId,
      categoryId: Value(transaction.categoryId),
      amount: transaction.amount,
      type: transaction.type.name,
      description: Value(transaction.description),
      date: transaction.date,
      notes: Value(transaction.notes),
      tags: Value(transaction.tags.isEmpty ? null : transaction.tags.join(',')),
      transferToAccountId: Value(transaction.transferToAccountId),
      recurringId: Value(transaction.recurringId),
      isSynced: const Value(false),
    );

    await _db.into(_db.transactions).insert(companion);

    // Actualizar balance de cuenta
    await _updateAccountBalance(
      transaction.accountId,
      transaction.signedAmount,
    );

    // Si es transferencia, actualizar cuenta destino
    if (transaction.isTransfer && transaction.transferToAccountId != null) {
      await _updateAccountBalance(
        transaction.transferToAccountId!,
        transaction.amount, // Positivo en destino
      );
    }

    return transaction.copyWith(isSynced: false);
  }

  /// Actualizar transaccion
  Future<void> updateTransaction(
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    // Revertir el balance anterior
    await _updateAccountBalance(
      oldTransaction.accountId,
      -oldTransaction.signedAmount,
    );
    if (oldTransaction.isTransfer && oldTransaction.transferToAccountId != null) {
      await _updateAccountBalance(
        oldTransaction.transferToAccountId!,
        -oldTransaction.amount,
      );
    }

    // Actualizar transaccion
    await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(newTransaction.id)))
        .write(TransactionsCompanion(
      accountId: Value(newTransaction.accountId),
      categoryId: Value(newTransaction.categoryId),
      amount: Value(newTransaction.amount),
      type: Value(newTransaction.type.name),
      description: Value(newTransaction.description),
      date: Value(newTransaction.date),
      notes: Value(newTransaction.notes),
      tags: Value(newTransaction.tags.isEmpty ? null : newTransaction.tags.join(',')),
      transferToAccountId: Value(newTransaction.transferToAccountId),
      isSynced: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));

    // Aplicar nuevo balance
    await _updateAccountBalance(
      newTransaction.accountId,
      newTransaction.signedAmount,
    );
    if (newTransaction.isTransfer && newTransaction.transferToAccountId != null) {
      await _updateAccountBalance(
        newTransaction.transferToAccountId!,
        newTransaction.amount,
      );
    }
  }

  /// Eliminar transaccion
  Future<void> deleteTransaction(TransactionModel transaction) async {
    // Revertir balance
    await _updateAccountBalance(
      transaction.accountId,
      -transaction.signedAmount,
    );
    if (transaction.isTransfer && transaction.transferToAccountId != null) {
      await _updateAccountBalance(
        transaction.transferToAccountId!,
        -transaction.amount,
      );
    }

    // Eliminar
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(transaction.id))).go();
  }

  /// Actualizar balance de cuenta
  Future<void> _updateAccountBalance(String accountId, double delta) async {
    final account = await _accountRepository.getAccountById(accountId);
    if (account != null) {
      await _accountRepository.updateBalance(
        accountId,
        account.balance + delta,
      );
    }
  }

  /// Contar transacciones asociadas a una cuenta
  Future<int> countTransactionsByAccount(String accountId) async {
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.id.count()])
      ..where(_db.transactions.accountId.equals(accountId));

    final result = await query.getSingleOrNull();
    return result?.read(_db.transactions.id.count()) ?? 0;
  }

  /// Obtener transacciones no sincronizadas
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final query = _db.select(_db.transactions)
      ..where((t) => t.isSynced.equals(false));
    final results = await query.get();
    return results.map((tx) => _transactionFromRow(tx)).toList();
  }

  /// Marcar como sincronizada
  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(isSynced: Value(true)),
    );
  }

  // ==================== CATEGORIAS ====================

  /// Obtener todas las categorias
  Stream<List<CategoryModel>> watchCategories() {
    return (_db.select(_db.categories)
          ..orderBy([
            (t) => OrderingTerm.asc(t.type),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch()
        .map((rows) => rows.map(_categoryFromRow).toList());
  }

  /// Obtener categorias por tipo
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final query = _db.select(_db.categories)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final results = await query.get();
    return results.map(_categoryFromRow).toList();
  }

  /// Crear categoria
  Future<CategoryModel> createCategory({
    required String userId,
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final uuid = _uuid.v4();

    final id = await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        uuid: uuid,
        userId: Value(userId),
        name: name,
        type: type,
        icon: Value(icon),
        color: Value(color),
        isSystem: const Value(false),
        synced: const Value(false),
      ),
    );

    // Sync to Supabase
    try {
      if (!_isOnline) throw Exception('Offline mode');
      final response = await _supabase!.from('categories').insert({
        'user_id': userId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'is_system': false,
      }).select().single();

      // Update local with remote UUID
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          uuid: Value(response['id'] as String),
          synced: const Value(true),
        ),
      );
    } catch (_) {
      // Will sync later
    }

    final result = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingle();
    return _categoryFromRow(result);
  }

  /// Actualizar categoria
  Future<void> updateCategory({
    required int id,
    required String name,
    String? icon,
    String? color,
  }) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        color: Value(color),
        synced: const Value(false),
      ),
    );

    // Get UUID for sync
    final cat = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingle();

    try {
      if (!_isOnline) throw Exception('Offline mode');
      await _supabase!.from('categories').update({
        'name': name,
        'icon': icon,
        'color': color,
      }).eq('id', cat.uuid);

      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        const CategoriesCompanion(synced: Value(true)),
      );
    } catch (_) {
      // Will sync later
    }
  }

  /// Eliminar categoria
  Future<bool> deleteCategory(int id) async {
    // Check if category is in use
    final usageCount = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(id)))
        .get();

    if (usageCount.isNotEmpty) {
      return false; // Cannot delete, category is in use
    }

    final cat = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (cat == null) return false;

    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();

    try {
      if (_isOnline) await _supabase!.from('categories').delete().eq('id', cat.uuid);
    } catch (_) {
      // Ignore remote errors
    }

    return true;
  }

  /// Verificar si categoria esta en uso
  Future<int> getCategoryUsageCount(int id) async {
    final result = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(id)))
        .get();
    return result.length;
  }

  // ==================== ESTADISTICAS ====================

  /// Obtener totales por tipo en un periodo
  Future<Map<TransactionType, double>> getTotalsByType(
    String userId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.date.isBiggerOrEqualValue(fromDate) &
          t.date.isSmallerOrEqualValue(toDate));

    final results = await query.get();

    final totals = <TransactionType, double>{
      TransactionType.income: 0,
      TransactionType.expense: 0,
      TransactionType.transfer: 0,
    };

    for (final tx in results) {
      final type = TransactionType.values.firstWhere(
        (e) => e.name == tx.type,
        orElse: () => TransactionType.expense,
      );
      totals[type] = (totals[type] ?? 0) + tx.amount;
    }

    return totals;
  }

  /// Obtener gastos por categoria
  Future<Map<int, double>> getExpensesByCategory(
    String userId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.type.equals('expense') &
          t.date.isBiggerOrEqualValue(fromDate) &
          t.date.isSmallerOrEqualValue(toDate));

    final results = await query.get();
    final byCategory = <int, double>{};

    for (final tx in results) {
      if (tx.categoryId != null) {
        byCategory[tx.categoryId!] = (byCategory[tx.categoryId!] ?? 0) + tx.amount;
      }
    }

    return byCategory;
  }

  // ==================== SYNC ====================

  /// Sincronizar transacciones con Supabase
  Future<void> syncWithSupabase(String userId) async {
    try {
      // Subir no sincronizadas
      final unsynced = await getUnsyncedTransactions();
      for (final tx in unsynced) {
        await _upsertToSupabase(tx);
        await markAsSynced(tx.id);
      }

      // Descargar del servidor (ultimos 3 meses)
      final fromDate = DateTime.now().subtract(const Duration(days: 90));
      final remote = await _fetchFromSupabase(userId, fromDate);

      for (final remoteTx in remote) {
        final local = await getTransactionById(remoteTx.id);
        if (local == null) {
          await _insertFromRemote(remoteTx);
        } else if (!local.isSynced) {
          // Priorizar local
          await _upsertToSupabase(local);
          await markAsSynced(local.id);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _upsertToSupabase(TransactionModel tx) async {
    if (_isOnline) await _supabase!.from('transactions').upsert(tx.toSupabaseMap());
  }

  Future<List<TransactionModel>> _fetchFromSupabase(String userId, DateTime fromDate) async {
    if (!_isOnline) return [];
    final response = await _supabase!
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('date', fromDate.toIso8601String())
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _insertFromRemote(TransactionModel tx) async {
    final companion = TransactionsCompanion.insert(
      id: tx.id,
      userId: tx.userId,
      accountId: tx.accountId,
      categoryId: Value(tx.categoryId),
      amount: tx.amount,
      type: tx.type.name,
      description: Value(tx.description),
      date: tx.date,
      notes: Value(tx.notes),
      tags: Value(tx.tags.isEmpty ? null : tx.tags.join(',')),
      transferToAccountId: Value(tx.transferToAccountId),
      recurringId: Value(tx.recurringId),
      isSynced: const Value(true),
      createdAt: Value(tx.createdAt ?? DateTime.now()),
      updatedAt: Value(tx.updatedAt),
    );

    await _db.into(_db.transactions).insertOnConflictUpdate(companion);
  }

  // ==================== HELPERS ====================

  TransactionModel _transactionFromRow(
    Transaction row, {
    Category? category,
    Account? account,
  }) {
    return TransactionModel(
      id: row.id,
      userId: row.userId,
      accountId: row.accountId,
      categoryId: row.categoryId,
      amount: row.amount,
      type: TransactionType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => TransactionType.expense,
      ),
      description: row.description,
      date: row.date,
      notes: row.notes,
      tags: row.tags?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      transferToAccountId: row.transferToAccountId,
      recurringId: row.recurringId,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      // UI fields
      categoryName: category?.name,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
      accountName: account?.name,
    );
  }

  CategoryModel _categoryFromRow(Category row) {
    return CategoryModel(
      id: row.id,
      uuid: row.uuid,
      userId: row.userId,
      familyId: row.familyId,
      name: row.name,
      type: row.type,
      icon: row.icon,
      color: row.color,
      parentId: row.parentId,
      isSystem: row.isSystem,
      isSynced: row.synced,
      createdAt: row.createdAt,
    );
  }
}
