import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/dashboard/indicator_status.dart';
import 'database_provider.dart';

// Re-export para compatibilidad con código existente
export '../../domain/entities/dashboard/indicator_status.dart';

part 'financial_indicators_provider.g.dart';

// ============================================================
// INDICADORES DE DOMINIO (Modelos puros sin dependencia de DB)
// ============================================================

/// Indicador de Cobertura de Deuda
/// ¿Tengo suficiente en Bancos/Efectivo para cubrir mis deudas inmediatas?
class DebtCoverageIndicator {
  final double availableCash;
  final double immediateDebts;

  const DebtCoverageIndicator({
    required this.availableCash,
    required this.immediateDebts,
  });

  /// Ratio de cobertura (disponible / deudas)
  double get ratio => immediateDebts == 0 ? double.infinity : availableCash / immediateDebts;

  /// Si tiene cobertura completa (ratio >= 1)
  bool get hasFullCoverage => ratio >= 1.0;

  /// Estado del indicador
  IndicatorStatus get status {
    if (ratio >= 1.5) return IndicatorStatus.good;
    if (ratio >= 0.8) return IndicatorStatus.warning;
    return IndicatorStatus.danger;
  }

  /// Mensaje descriptivo
  String get message {
    if (hasFullCoverage) {
      return 'Puedes cubrir tus deudas ${ratio.toStringAsFixed(1)}x';
    }
    return 'Te falta \$${(immediateDebts - availableCash).toStringAsFixed(0)} para cubrir deudas';
  }
}

/// Indicador de Peso del Mercado (Alimentación)
/// % de ingresos destinado a Alimentación
class FoodWeightIndicator {
  final double totalIncome;
  final double foodExpenses;

  const FoodWeightIndicator({
    required this.totalIncome,
    required this.foodExpenses,
  });

  /// Porcentaje de ingresos en alimentación
  double get percentage => totalIncome == 0 ? 0 : (foodExpenses / totalIncome) * 100;

  /// Estado del indicador
  /// < 30% = good, 30-40% = warning, > 40% = danger
  IndicatorStatus get status {
    if (percentage <= 30) return IndicatorStatus.good;
    if (percentage <= 40) return IndicatorStatus.warning;
    return IndicatorStatus.danger;
  }

  String get message => '${percentage.toStringAsFixed(1)}% de tus ingresos va a alimentación';
}

/// Indicador de Índice Saludable
/// Comparación entre gasto en Frutas/Verduras vs Mecato/Domicilios
class HealthyIndexIndicator {
  final double healthySpending;
  final double unhealthySpending;

  const HealthyIndexIndicator({
    required this.healthySpending,
    required this.unhealthySpending,
  });

  /// Ratio saludable (saludable / no saludable)
  double get ratio => unhealthySpending == 0 ? double.infinity : healthySpending / unhealthySpending;

  /// Si el gasto es predominantemente saludable
  bool get isHealthy => ratio > 1.0;

  /// Estado del indicador
  /// ratio > 2 = good, ratio 1-2 = warning, ratio < 1 = danger
  IndicatorStatus get status {
    if (ratio >= 2.0) return IndicatorStatus.good;
    if (ratio >= 1.0) return IndicatorStatus.warning;
    return IndicatorStatus.danger;
  }

  String get message {
    if (isHealthy) {
      return 'Gastas ${ratio.toStringAsFixed(1)}x más en comida saludable';
    }
    return 'Gastas más en mecato/domicilios que en comida saludable';
  }
}

/// Indicador de Costo Financiero
/// Total gastado en 4x1000 + Intereses de Tarjetas de Crédito
class FinancialCostIndicator {
  final double gmfCost; // 4x1000
  final double creditCardInterest;
  final double totalIncome;

  const FinancialCostIndicator({
    required this.gmfCost,
    required this.creditCardInterest,
    required this.totalIncome,
  });

  /// Costo financiero total
  double get totalCost => gmfCost + creditCardInterest;

  /// Porcentaje del ingreso que se va en costos financieros
  double get percentageOfIncome => totalIncome == 0 ? 0 : (totalCost / totalIncome) * 100;

  /// Estado del indicador
  /// < 2% = good, 2-5% = warning, > 5% = danger
  IndicatorStatus get status {
    if (percentageOfIncome <= 2) return IndicatorStatus.good;
    if (percentageOfIncome <= 5) return IndicatorStatus.warning;
    return IndicatorStatus.danger;
  }

  String get message => '\$${totalCost.toStringAsFixed(0)} en costos financieros (${percentageOfIncome.toStringAsFixed(1)}%)';
}

/// Indicador de Saldo Disponible Real
/// (Efectivo + Bancos) - (Cuentas por Pagar Inmediatas)
class AvailableBalanceIndicator {
  final double cashBalance;
  final double bankBalance;
  final double immediatePayables;

  const AvailableBalanceIndicator({
    required this.cashBalance,
    required this.bankBalance,
    required this.immediatePayables,
  });

  /// Saldo bruto (efectivo + bancos)
  double get grossBalance => cashBalance + bankBalance;

  /// Saldo neto disponible
  double get netBalance => grossBalance - immediatePayables;

  /// Si tiene saldo positivo
  bool get hasPositiveBalance => netBalance > 0;

  /// Estado del indicador
  IndicatorStatus get status {
    if (netBalance > 0) return IndicatorStatus.good;
    if (netBalance >= -100000) return IndicatorStatus.warning; // Tolerancia de 100K
    return IndicatorStatus.danger;
  }

  String get message {
    if (hasPositiveBalance) {
      return 'Tienes \$${netBalance.toStringAsFixed(0)} disponibles';
    }
    return 'Estás en rojo: -\$${(-netBalance).toStringAsFixed(0)}';
  }
}

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
  final liabilityCategories = await categoriesDao.getCategoriesByType('liability');

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
      .where((c) => c.name.contains('Banco') || c.name.contains('Digital') ||
                    c.name.contains('Nequi') || c.name.contains('Davi'))
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
  final availableBalance = await ref.watch(availableBalanceIndicatorProvider.future);

  return FinancialIndicatorsSummary(
    debtCoverage: debtCoverage,
    availableBalance: availableBalance,
  );
}

/// Resumen de todos los indicadores
class FinancialIndicatorsSummary {
  final DebtCoverageIndicator debtCoverage;
  final AvailableBalanceIndicator availableBalance;
  // TODO: Agregar más indicadores cuando tengamos transacciones

  const FinancialIndicatorsSummary({
    required this.debtCoverage,
    required this.availableBalance,
  });

  /// Estado general (el peor de todos los indicadores)
  IndicatorStatus get overallStatus {
    final statuses = [
      debtCoverage.status,
      availableBalance.status,
    ];

    if (statuses.contains(IndicatorStatus.danger)) {
      return IndicatorStatus.danger;
    }
    if (statuses.contains(IndicatorStatus.warning)) {
      return IndicatorStatus.warning;
    }
    return IndicatorStatus.good;
  }
}
