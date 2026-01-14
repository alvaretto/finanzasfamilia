import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/accounts_table.dart';

part 'accounts_dao.g.dart';

/// DAO para operaciones CRUD de cuentas
@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  /// Obtiene todas las cuentas activas
  /// Considera isActive = NULL como activa (valor por defecto)
  Future<List<AccountEntry>> getActiveAccounts() {
    return (select(accounts)
          ..where((a) => a.isActive.equals(true) | a.isActive.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .get();
  }

  /// Obtiene todas las cuentas (activas e inactivas)
  Future<List<AccountEntry>> getAllAccounts() {
    return (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.name)])).get();
  }

  /// Obtiene una cuenta por ID
  Future<AccountEntry?> getAccountById(String id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Obtiene cuentas por categoría
  /// Considera isActive = NULL como activa (valor por defecto)
  Future<List<AccountEntry>> getAccountsByCategory(String categoryId) {
    return (select(accounts)
          ..where((a) => a.categoryId.equals(categoryId))
          ..where((a) => a.isActive.equals(true) | a.isActive.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .get();
  }

  /// Inserta una nueva cuenta
  Future<void> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  /// Actualiza una cuenta existente
  Future<void> updateAccount(AccountsCompanion account) {
    return (update(accounts)..where((a) => a.id.equals(account.id.value)))
        .write(account);
  }

  /// Actualiza el saldo de una cuenta
  Future<void> updateBalance(String accountId, double newBalance) {
    return (update(accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(
        balance: Value(newBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Desactiva una cuenta (soft delete)
  Future<void> deactivateAccount(String id) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina una cuenta permanentemente
  Future<void> deleteAccount(String id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  /// Stream de cuentas activas para UI reactiva
  /// Considera isActive = NULL como activa (valor por defecto)
  Stream<List<AccountEntry>> watchActiveAccounts() {
    return (select(accounts)
          ..where((a) => a.isActive.equals(true) | a.isActive.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  /// Obtiene el balance total de todas las cuentas que incluyen en total
  /// Considera isActive = NULL e includeInTotal = NULL como true (valores por defecto)
  Future<double> getTotalBalance() async {
    final accountsList = await (select(accounts)
          ..where((a) => a.isActive.equals(true) | a.isActive.isNull())
          ..where((a) => a.includeInTotal.equals(true) | a.includeInTotal.isNull()))
        .get();

    double total = 0.0;
    for (final account in accountsList) {
      total += account.balance ?? 0.0;
    }
    return total;
  }
}
