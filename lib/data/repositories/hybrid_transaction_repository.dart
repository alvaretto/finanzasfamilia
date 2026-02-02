import 'package:drift/drift.dart';

import '../../domain/repositories/transaction_repository.dart';
import '../local/database.dart';
import '../remote/supabase_write_service.dart';

/// Repositorio híbrido de transacciones
///
/// ARQUITECTURA: Online-first writes, local reads
/// - Reads: Drift (local, rápido, offline-capable)
/// - Writes: Supabase directo → luego Drift local para consistencia inmediata
///
/// Flujo de write:
/// 1. Escribe a Supabase (source of truth)
/// 2. Si éxito, escribe a Drift local (para UI inmediata)
/// 3. PowerSync eventualmente sincroniza (pero ya tenemos el dato local)
class HybridTransactionRepository implements TransactionRepository {
  final AppDatabase _db;
  final SupabaseWriteService _supabaseWrite;

  HybridTransactionRepository(this._db, this._supabaseWrite);

  String? get _currentUserId => _supabaseWrite.currentUserId;

  @override
  Future<TransactionData?> getTransactionById(String id) async {
    // READ: desde Drift (local)
    final entry = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return null;
    return _toTransactionData(entry);
  }

  @override
  Future<void> insertTransaction(TransactionData transaction) async {
    final now = DateTime.now();

    // Preparar datos para Supabase
    final supabaseData = {
      'id': transaction.id,
      'user_id': _currentUserId,
      'type': transaction.type,
      'amount': transaction.amount,
      'description': transaction.description,
      'category_id': transaction.categoryId,
      'from_account_id': transaction.fromAccountId,
      'to_account_id': transaction.toAccountId,
      'transaction_date': transaction.transactionDate.toIso8601String(),
      'satisfaction_level': transaction.satisfactionLevel,
      'created_at': (transaction.createdAt).toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    // 1. WRITE: Supabase primero (source of truth)
    await _supabaseWrite.upsertTransaction(supabaseData);

    // 2. WRITE: Drift local (para UI inmediata)
    await _db.into(_db.transactions).insertOnConflictUpdate(
      TransactionsCompanion.insert(
        id: transaction.id,
        userId: Value(_currentUserId),
        type: transaction.type,
        amount: transaction.amount,
        description: Value(transaction.description),
        categoryId: transaction.categoryId,
        fromAccountId: Value(transaction.fromAccountId),
        toAccountId: Value(transaction.toAccountId),
        transactionDate: transaction.transactionDate,
        satisfactionLevel: Value(transaction.satisfactionLevel),
        createdAt: Value(transaction.createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // 1. DELETE: Supabase primero
    await _supabaseWrite.deleteTransaction(id);

    // 2. DELETE: Drift local
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<TransactionData>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    // READ: desde Drift (local)
    final entries = await (_db.select(_db.transactions)
          ..where((t) => t.transactionDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();

    return entries.map(_toTransactionData).toList();
  }

  TransactionData _toTransactionData(TransactionEntry entry) {
    return TransactionData(
      id: entry.id,
      type: entry.type,
      amount: entry.amount,
      description: entry.description,
      categoryId: entry.categoryId,
      fromAccountId: entry.fromAccountId,
      toAccountId: entry.toAccountId,
      transactionDate: entry.transactionDate,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
      satisfactionLevel: entry.satisfactionLevel,
    );
  }
}
