import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mappers/account_display_mappers.dart';
import '../../data/repositories/repositories.dart';
import '../../data/repositories/hybrid_transaction_repository.dart';
import '../../data/repositories/hybrid_journal_entry_repository.dart';
import '../../domain/entities/accounts/accounts.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/journal_entry_repository.dart';
import '../../domain/services/accounting_service.dart';
import 'database_provider.dart';
import 'supabase_write_provider.dart';

// Re-export para compatibilidad
export '../../domain/entities/accounts/accounts.dart';

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

/// Provider del repositorio de transacciones (HÍBRIDO)
/// Writes → Supabase directo, Reads → Drift local
@riverpod
TransactionRepository transactionRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabaseWrite = ref.watch(supabaseWriteServiceProvider);
  return HybridTransactionRepository(db, supabaseWrite);
}

/// Provider del repositorio de asientos contables (HÍBRIDO)
/// Writes → Supabase directo, Reads → Drift local
@riverpod
JournalEntryRepository journalEntryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabaseWrite = ref.watch(supabaseWriteServiceProvider);
  return HybridJournalEntryRepository(db, supabaseWrite);
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
Future<List<AccountWithCategoryDto>> activeAccounts(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final accountsDao = ref.watch(accountsDaoProvider);

  final accounts = await accountsDao.getActiveAccounts();

  // Obtener información de categoría para cada cuenta
  final result = <AccountWithCategoryDto>[];
  for (final account in accounts) {
    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(account.categoryId)))
        .getSingleOrNull();

    result.add(AccountDisplayMappers.accountWithCategoryToDto(account, category));
  }

  return result;
}

/// Provider para obtener cuentas por tipo de categoría
@riverpod
Future<List<AccountWithCategoryDto>> accountsByType(
  Ref ref,
  String categoryType,
) async {
  final db = ref.watch(appDatabaseProvider);
  final accountsDao = ref.watch(accountsDaoProvider);

  final accounts = await accountsDao.getActiveAccounts();

  // Filtrar por tipo de categoría
  final result = <AccountWithCategoryDto>[];
  for (final account in accounts) {
    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(account.categoryId)))
        .getSingleOrNull();

    if (category?.type == categoryType) {
      result.add(AccountDisplayMappers.accountWithCategoryToDto(account, category));
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
    if (!(account.includeInTotal ?? true)) continue;

    includedCount++;

    final category = await (db.select(db.categories)
          ..where((c) => c.id.equals(account.categoryId)))
        .getSingleOrNull();

    if (category?.type == 'asset') {
      totalAssets += account.balance ?? 0.0;
    } else if (category?.type == 'liability') {
      totalLiabilities += account.balance ?? 0.0;
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

// NOTA: Los modelos están en domain/entities/accounts/
// - AccountWithCategoryDto
// - AccountDisplayDto
// - TotalBalance
