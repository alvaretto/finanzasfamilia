import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/accounting_service.dart';
import 'database_provider.dart';

part 'accounting_provider.g.dart';

/// Provider del servicio de contabilidad (Partida Doble)
@riverpod
AccountingService accountingService(AccountingServiceRef ref) {
  final db = ref.watch(appDatabaseProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final journalEntriesDao = ref.watch(journalEntriesDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);

  return AccountingService(
    db: db,
    transactionsDao: transactionsDao,
    journalEntriesDao: journalEntriesDao,
    categoriesDao: categoriesDao,
  );
}

/// Provider para obtener todas las cuentas activas
@riverpod
Future<List<AccountWithCategory>> activeAccounts(ActiveAccountsRef ref) async {
  final db = ref.watch(appDatabaseProvider);
  final accountsDao = ref.watch(accountsDaoProvider);

  final accounts = await accountsDao.getActiveAccounts();

  // Obtener información de categoría para cada cuenta
  final result = <AccountWithCategory>[];
  for (final account in accounts) {
    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(account.categoryId)))
        .getSingleOrNull();

    result.add(AccountWithCategory(
      account: account,
      categoryName: category?.name ?? 'Sin categoría',
      categoryType: category?.type ?? 'asset',
    ));
  }

  return result;
}

/// Provider para obtener cuentas por tipo de categoría
@riverpod
Future<List<AccountWithCategory>> accountsByType(
  AccountsByTypeRef ref,
  String categoryType,
) async {
  final db = ref.watch(appDatabaseProvider);
  final accountsDao = ref.watch(accountsDaoProvider);

  final accounts = await accountsDao.getActiveAccounts();

  // Filtrar por tipo de categoría
  final result = <AccountWithCategory>[];
  for (final account in accounts) {
    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(account.categoryId)))
        .getSingleOrNull();

    if (category?.type == categoryType) {
      result.add(AccountWithCategory(
        account: account,
        categoryName: category?.name ?? 'Sin categoría',
        categoryType: category?.type ?? 'asset',
      ));
    }
  }

  return result;
}

/// Provider para obtener el balance total de todas las cuentas activas
@riverpod
Future<TotalBalance> totalBalance(TotalBalanceRef ref) async {
  final accountsDao = ref.watch(accountsDaoProvider);
  final accounts = await accountsDao.getActiveAccounts();

  double totalAssets = 0;
  double totalLiabilities = 0;
  int includedCount = 0;

  final db = ref.watch(appDatabaseProvider);

  for (final account in accounts) {
    if (!account.includeInTotal) continue;

    includedCount++;

    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(account.categoryId)))
        .getSingleOrNull();

    if (category?.type == 'asset') {
      totalAssets += account.balance;
    } else if (category?.type == 'liability') {
      totalLiabilities += account.balance;
    }
  }

  return TotalBalance(
    assets: totalAssets,
    liabilities: totalLiabilities,
    netWorth: totalAssets - totalLiabilities,
    accountCount: includedCount,
  );
}

/// Modelo para cuenta con información de categoría
class AccountWithCategory {
  final dynamic account;
  final String categoryName;
  final String categoryType;

  AccountWithCategory({
    required this.account,
    required this.categoryName,
    required this.categoryType,
  });
}

/// Modelo para balance total
class TotalBalance {
  final double assets;
  final double liabilities;
  final double netWorth;
  final int accountCount;

  TotalBalance({
    required this.assets,
    required this.liabilities,
    required this.netWorth,
    required this.accountCount,
  });

  /// Balance neto (alias para netWorth)
  double get balance => netWorth;
}
