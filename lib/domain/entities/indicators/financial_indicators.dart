import '../dashboard/indicator_status.dart';

// ============================================================
// INDICADORES FINANCIEROS DE DOMINIO (Modelos puros)
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
  double get ratio =>
      immediateDebts == 0 ? double.infinity : availableCash / immediateDebts;

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
  double get percentage =>
      totalIncome == 0 ? 0 : (foodExpenses / totalIncome) * 100;

  /// Estado del indicador
  /// < 30% = good, 30-40% = warning, > 40% = danger
  IndicatorStatus get status {
    if (percentage <= 30) return IndicatorStatus.good;
    if (percentage <= 40) return IndicatorStatus.warning;
    return IndicatorStatus.danger;
  }

  String get message =>
      '${percentage.toStringAsFixed(1)}% de tus ingresos va a alimentación';
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
  double get ratio => unhealthySpending == 0
      ? double.infinity
      : healthySpending / unhealthySpending;

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
  double get percentageOfIncome =>
      totalIncome == 0 ? 0 : (totalCost / totalIncome) * 100;

  /// Estado del indicador
  /// < 2% = good, 2-5% = warning, > 5% = danger
  IndicatorStatus get status {
    if (percentageOfIncome <= 2) return IndicatorStatus.good;
    if (percentageOfIncome <= 5) return IndicatorStatus.warning;
    return IndicatorStatus.danger;
  }

  String get message =>
      '\$${totalCost.toStringAsFixed(0)} en costos financieros (${percentageOfIncome.toStringAsFixed(1)}%)';
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

/// Resumen de todos los indicadores financieros
class FinancialIndicatorsSummary {
  final DebtCoverageIndicator debtCoverage;
  final AvailableBalanceIndicator availableBalance;

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
