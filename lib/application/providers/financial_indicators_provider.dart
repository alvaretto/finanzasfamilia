import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/indicators/financial_indicators.dart';
import 'database_provider.dart';

// Re-export para compatibilidad con código existente
export '../../domain/entities/dashboard/indicator_status.dart';
export '../../domain/entities/indicators/financial_indicators.dart';

part 'financial_indicators_provider.g.dart';

// ============================================================
// PROVIDERS (Conectan los indicadores con la base de datos)
// ============================================================

/// Provider del indicador de cobertura de deuda
@riverpod
Future<DebtCoverageIndicator> debtCoverageIndicator(
  Ref ref,
) async {
  final db = ref.watch(appDatabaseProvider);

  // Obtener cuentas de activos (efectivo + bancos)
  final accounts = await db.select(db.accounts).get();

  double availableCash = 0;
  double immediateDebts = 0;

  for (final account in accounts) {
    // Aquí necesitaríamos verificar la categoría del account
    // Por ahora sumamos todos los balances positivos como disponibles
    // y los negativos como deudas
    if (account.balance >= 0) {
      availableCash += account.balance;
    } else {
      immediateDebts += account.balance.abs();
    }
  }

  return DebtCoverageIndicator(
    availableCash: availableCash,
    immediateDebts: immediateDebts,
  );
}

/// Provider del saldo disponible real
@riverpod
Future<AvailableBalanceIndicator> availableBalanceIndicator(
  Ref ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);

  // Obtener categorías de efectivo y bancos
  final assetCategories = await categoriesDao.getCategoriesByType('asset');
  final liabilityCategories =
      await categoriesDao.getCategoriesByType('liability');

  final accounts = await db.select(db.accounts).get();

  double cashBalance = 0;
  double bankBalance = 0;
  double immediatePayables = 0;

  // Identificar IDs de categorías relevantes
  final cashCategoryIds = assetCategories
      .where((c) => c.name.contains('Efectivo') || c.name.contains('Billetera'))
      .map((c) => c.id)
      .toSet();

  final bankCategoryIds = assetCategories
      .where((c) =>
          c.name.contains('Banco') ||
          c.name.contains('Digital') ||
          c.name.contains('Nequi') ||
          c.name.contains('Davi'))
      .map((c) => c.id)
      .toSet();

  final payableCategoryIds = liabilityCategories
      .where((c) => c.name.contains('Tarjeta') || c.name.contains('Pagar'))
      .map((c) => c.id)
      .toSet();

  for (final account in accounts) {
    if (cashCategoryIds.contains(account.categoryId)) {
      cashBalance += account.balance;
    } else if (bankCategoryIds.contains(account.categoryId)) {
      bankBalance += account.balance;
    } else if (payableCategoryIds.contains(account.categoryId)) {
      immediatePayables += account.balance.abs();
    }
  }

  return AvailableBalanceIndicator(
    cashBalance: cashBalance,
    bankBalance: bankBalance,
    immediatePayables: immediatePayables,
  );
}

/// Provider de todos los indicadores financieros
@riverpod
Future<FinancialIndicatorsSummary> financialIndicatorsSummary(
  Ref ref,
) async {
  final debtCoverage = await ref.watch(debtCoverageIndicatorProvider.future);
  final availableBalance =
      await ref.watch(availableBalanceIndicatorProvider.future);

  return FinancialIndicatorsSummary(
    debtCoverage: debtCoverage,
    availableBalance: availableBalance,
  );
}
