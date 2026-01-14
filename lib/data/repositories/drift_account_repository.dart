import 'package:drift/drift.dart';

import '../../domain/repositories/account_repository.dart';
import '../local/database.dart';

/// Implementación concreta de AccountRepository usando Drift.
class DriftAccountRepository implements AccountRepository {
  final AppDatabase _db;

  DriftAccountRepository(this._db);

  @override
  Future<AccountData?> getAccountById(String id) async {
    final entry = await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return null;
    return _toAccountData(entry);
  }

  @override
  Future<List<AccountData>> getActiveAccounts() async {
    final entries = await (_db.select(_db.accounts)
          ..where((a) => a.isActive.equals(true) | a.isActive.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .get();

    return entries.map(_toAccountData).toList();
  }

  @override
  Future<void> updateBalance(String accountId, double newBalance) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(
      balance: Value(newBalance),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<bool> accountExists(String accountId) async {
    final account = await getAccountById(accountId);
    return account != null;
  }

  @override
  Future<AccountWithCategoryData?> getAccountWithCategoryById(String id) async {
    final query = _db.select(_db.accounts).join([
      leftOuterJoin(
          _db.categories, _db.categories.id.equalsExp(_db.accounts.categoryId)),
    ])
      ..where(_db.accounts.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final account = result.readTable(_db.accounts);
    final category = result.readTableOrNull(_db.categories);

    return AccountWithCategoryData(
      account: _toAccountData(account),
      categoryType: category?.type ?? 'asset',
      categoryName: category?.name ?? 'Sin categoría',
    );
  }

  AccountData _toAccountData(AccountEntry entry) {
    return AccountData(
      id: entry.id,
      name: entry.name,
      categoryId: entry.categoryId,
      balance: entry.balance ?? 0.0,
      isActive: entry.isActive ?? true,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
    );
  }
}
