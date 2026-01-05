import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/account_model.dart';

/// Repositorio de cuentas con soporte offline-first
class AccountRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;

  AccountRepository({
    AppDatabase? database,
    SupabaseClient? supabaseClient,
  })  : _db = database ?? AppDatabase.instance,
        _supabase = supabaseClient ?? SupabaseClientProvider.clientOrNull;

  /// Verifica si Supabase está disponible
  bool get _isOnline => _supabase != null && SupabaseClientProvider.isInitialized;

  // ==================== OPERACIONES LOCALES ====================

  /// Obtener todas las cuentas del usuario
  Stream<List<AccountModel>> watchAccounts(String userId) {
    return (_db.select(_db.accounts)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_accountFromRow).toList());
  }

  /// Obtener cuentas activas
  Stream<List<AccountModel>> watchActiveAccounts(String userId) {
    return (_db.select(_db.accounts)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_accountFromRow).toList());
  }

  /// Obtener una cuenta por ID
  Future<AccountModel?> getAccountById(String id) async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _accountFromRow(result) : null;
  }

  /// Crear cuenta localmente
  Future<AccountModel> createAccount(AccountModel account) async {
    final companion = AccountsCompanion.insert(
      id: account.id,
      userId: account.userId,
      familyId: Value(account.familyId),
      name: account.name,
      type: account.type.name,
      currency: Value(account.currency),
      balance: Value(account.balance),
      creditLimit: Value(account.creditLimit),
      color: Value(account.color),
      icon: Value(account.icon),
      bankName: Value(account.bankName),
      lastFourDigits: Value(account.lastFourDigits),
      isActive: Value(account.isActive),
      includeInTotal: Value(account.includeInTotal),
      isSynced: const Value(false),
    );

    await _db.into(_db.accounts).insert(companion);
    return account.copyWith(isSynced: false);
  }

  /// Actualizar cuenta localmente
  Future<void> updateAccount(AccountModel account) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(account.id)))
        .write(AccountsCompanion(
      name: Value(account.name),
      type: Value(account.type.name),
      currency: Value(account.currency),
      balance: Value(account.balance),
      creditLimit: Value(account.creditLimit),
      color: Value(account.color),
      icon: Value(account.icon),
      bankName: Value(account.bankName),
      lastFourDigits: Value(account.lastFourDigits),
      isActive: Value(account.isActive),
      includeInTotal: Value(account.includeInTotal),
      isSynced: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Eliminar cuenta localmente (soft delete)
  Future<void> deleteAccount(String id) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      const AccountsCompanion(
        isActive: Value(false),
        isSynced: Value(false),
      ),
    );
  }

  /// Eliminar cuenta permanentemente
  Future<void> hardDeleteAccount(String id) async {
    await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  /// Actualizar balance de cuenta
  Future<void> updateBalance(String id, double newBalance) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        balance: Value(newBalance),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Obtener cuentas no sincronizadas
  Future<List<AccountModel>> getUnsyncedAccounts() async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.isSynced.equals(false));
    final results = await query.get();
    return results.map(_accountFromRow).toList();
  }

  /// Marcar cuenta como sincronizada
  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      const AccountsCompanion(isSynced: Value(true)),
    );
  }

  /// Calcular balance total
  Future<double> getTotalBalance(String userId) async {
    final query = _db.select(_db.accounts)
      ..where((t) =>
          t.userId.equals(userId) &
          t.isActive.equals(true) &
          t.includeInTotal.equals(true));
    final accounts = await query.get();

    double total = 0;
    for (final account in accounts) {
      if (account.type == 'credit') {
        total -= account.balance.abs(); // Las deudas restan
      } else {
        total += account.balance;
      }
    }
    return total;
  }

  // ==================== OPERACIONES REMOTAS ====================

  /// Sincronizar cuentas con Supabase
  Future<void> syncWithSupabase(String userId) async {
    if (!_isOnline) return; // Sin conexión, solo modo offline

    try {
      // 1. Subir cuentas locales no sincronizadas
      final unsyncedAccounts = await getUnsyncedAccounts();
      for (final account in unsyncedAccounts) {
        await _upsertToSupabase(account);
        await markAsSynced(account.id);
      }

      // 2. Descargar cuentas remotas
      final remoteAccounts = await _fetchFromSupabase(userId);

      // 3. Actualizar localmente
      for (final remote in remoteAccounts) {
        final local = await getAccountById(remote.id);
        if (local == null) {
          // Cuenta nueva del servidor
          await _insertFromRemote(remote);
        } else if (!local.isSynced) {
          // Conflicto: priorizar local (offline-first)
          await _upsertToSupabase(local);
          await markAsSynced(local.id);
        } else {
          // Actualizar desde servidor
          await _updateFromRemote(remote);
        }
      }
    } catch (e) {
      // Log error pero no lanzar - mantener funcionamiento offline
      rethrow;
    }
  }

  /// Subir/actualizar cuenta en Supabase
  Future<void> _upsertToSupabase(AccountModel account) async {
    if (!_isOnline) return;
    await _supabase!.from('accounts').upsert(account.toSupabaseMap());
  }

  /// Obtener cuentas de Supabase
  Future<List<AccountModel>> _fetchFromSupabase(String userId) async {
    if (!_isOnline) return [];

    final response = await _supabase!
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('name');

    return (response as List)
        .map((json) => AccountModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Insertar cuenta desde servidor
  Future<void> _insertFromRemote(AccountModel account) async {
    final companion = AccountsCompanion.insert(
      id: account.id,
      userId: account.userId,
      familyId: Value(account.familyId),
      name: account.name,
      type: account.type.name,
      currency: Value(account.currency),
      balance: Value(account.balance),
      creditLimit: Value(account.creditLimit),
      color: Value(account.color),
      icon: Value(account.icon),
      bankName: Value(account.bankName),
      lastFourDigits: Value(account.lastFourDigits),
      isActive: Value(account.isActive),
      includeInTotal: Value(account.includeInTotal),
      isSynced: const Value(true),
      createdAt: Value(account.createdAt ?? DateTime.now()),
      updatedAt: Value(account.updatedAt),
    );

    await _db.into(_db.accounts).insertOnConflictUpdate(companion);
  }

  /// Actualizar cuenta desde servidor
  Future<void> _updateFromRemote(AccountModel account) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(account.id)))
        .write(AccountsCompanion(
      name: Value(account.name),
      type: Value(account.type.name),
      currency: Value(account.currency),
      balance: Value(account.balance),
      creditLimit: Value(account.creditLimit),
      color: Value(account.color),
      icon: Value(account.icon),
      bankName: Value(account.bankName),
      lastFourDigits: Value(account.lastFourDigits),
      isActive: Value(account.isActive),
      includeInTotal: Value(account.includeInTotal),
      isSynced: const Value(true),
      updatedAt: Value(account.updatedAt),
    ));
  }

  /// Eliminar cuenta en Supabase
  Future<void> deleteFromSupabase(String id) async {
    if (!_isOnline) return;
    await _supabase!.from('accounts').delete().eq('id', id);
  }

  // ==================== HELPERS ====================

  AccountModel _accountFromRow(Account row) {
    return AccountModel(
      id: row.id,
      userId: row.userId,
      familyId: row.familyId,
      name: row.name,
      type: AccountType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => AccountType.bank,
      ),
      currency: row.currency,
      balance: row.balance,
      creditLimit: row.creditLimit,
      color: row.color,
      icon: row.icon,
      bankName: row.bankName,
      lastFourDigits: row.lastFourDigits,
      isActive: row.isActive,
      includeInTotal: row.includeInTotal,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isSynced: row.isSynced,
    );
  }
}
