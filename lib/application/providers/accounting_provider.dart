import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/repositories.dart';
import '../../domain/services/accounting_service.dart';
import 'database_provider.dart';

part 'accounting_provider.g.dart';

// ============================================================
// PROVIDERS DE REPOSITORIOS
// ============================================================

/// Provider del repositorio de cuentas
@riverpod
DriftAccountRepository accountRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftAccountRepository(db);
}

/// Provider del repositorio de transacciones
@riverpod
DriftTransactionRepository transactionRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTransactionRepository(db);
}

/// Provider del repositorio de asientos contables
@riverpod
DriftJournalEntryRepository journalEntryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftJournalEntryRepository(db);
}

/// Provider del repositorio de categorías
@riverpod
DriftCategoryRepository categoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCategoryRepository(db);
}

/// Provider del ejecutor de transacciones
@riverpod
DriftTransactionExecutor transactionExecutor(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTransactionExecutor(db);
}

// ============================================================
// PROVIDER DEL SERVICIO DE CONTABILIDAD
// ============================================================

/// Provider del servicio de contabilidad (Partida Doble)
/// Usa interfaces de repositorio para cumplir con Clean Architecture.
@riverpod
AccountingService accountingService(Ref ref) {
  return AccountingService(
    accountRepository: ref.watch(accountRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    journalEntryRepository: ref.watch(journalEntryRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    transactionExecutor: ref.watch(transactionExecutorProvider),
  );
}

// ============================================================
// PROVIDERS DE CONSULTAS
// ============================================================

/// Provider para obtener todas las cuentas activas
@riverpod
Future<List<AccountWithCategory>> activeAccounts(Ref ref) async {
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
  Ref ref,
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
Future<TotalBalance> totalBalance(Ref ref) async {
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

// ============================================================
// MODELOS DE DATOS
// ============================================================

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
