import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_summary.freezed.dart';
part 'financial_summary.g.dart';

/// Resumen de patrimonio neto inmutable
@freezed
class NetWorthSummary with _$NetWorthSummary {
  const NetWorthSummary._();

  const factory NetWorthSummary({
    /// Total de activos ("Lo que Tengo")
    required double totalAssets,

    /// Total de pasivos ("Lo que Debo")
    required double totalLiabilities,

    /// Fecha del cálculo
    required DateTime calculatedAt,
  }) = _NetWorthSummary;

  factory NetWorthSummary.fromJson(Map<String, dynamic> json) =>
      _$NetWorthSummaryFromJson(json);

  /// Patrimonio neto = Activos - Pasivos
  double get netWorth => totalAssets - totalLiabilities;

  /// Ratio de deuda (Pasivos / Activos)
  double get debtRatio {
    if (totalAssets <= 0) return 0;
    return totalLiabilities / totalAssets;
  }

  /// Verifica si el patrimonio es positivo
  bool get isPositive => netWorth > 0;

  /// Verifica si el patrimonio es negativo
  bool get isNegative => netWorth < 0;
}

/// Resumen mensual de ingresos y gastos inmutable
@freezed
class MonthlyFlowSummary with _$MonthlyFlowSummary {
  const MonthlyFlowSummary._();

  const factory MonthlyFlowSummary({
    required int month,
    required int year,

    /// Total de ingresos del mes
    required double totalIncome,

    /// Total de gastos del mes
    required double totalExpenses,

    /// Cantidad de transacciones
    @Default(0) int transactionCount,
  }) = _MonthlyFlowSummary;

  factory MonthlyFlowSummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlyFlowSummaryFromJson(json);

  /// Balance neto = Ingresos - Gastos
  double get netBalance => totalIncome - totalExpenses;

  /// Tasa de ahorro (% de ingresos ahorrados)
  double get savingsRate {
    if (totalIncome <= 0) return 0;
    return (netBalance / totalIncome) * 100;
  }

  /// Verifica si el balance es positivo (ahorrando)
  bool get isSaving => netBalance > 0;

  /// Verifica si el balance es negativo (gastando más de lo que entra)
  bool get isOverspending => netBalance < 0;

  /// Nombre del período
  String get periodName {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${months[month]} $year';
  }
}

/// Resumen de gastos por categoría inmutable
@freezed
class CategorySpending with _$CategorySpending {
  const CategorySpending._();

  const factory CategorySpending({
    required String categoryId,
    required String categoryName,
    String? categoryIcon,
    required double amount,

    /// Porcentaje del total de gastos
    required double percentage,

    /// Presupuesto asignado (si existe)
    double? budgetAmount,
  }) = _CategorySpending;

  factory CategorySpending.fromJson(Map<String, dynamic> json) =>
      _$CategorySpendingFromJson(json);

  /// Verifica si tiene presupuesto asignado
  bool get hasBudget => budgetAmount != null && budgetAmount! > 0;

  /// Porcentaje del presupuesto usado
  double get budgetPercentage {
    if (!hasBudget) return 0;
    return (amount / budgetAmount!) * 100;
  }

  /// Verifica si excedió el presupuesto
  bool get isOverBudget => hasBudget && amount > budgetAmount!;

  /// Monto disponible del presupuesto
  double get budgetRemaining {
    if (!hasBudget) return 0;
    return budgetAmount! - amount;
  }
}

/// Indicador de saldo disponible real inmutable
@freezed
class AvailableBalance with _$AvailableBalance {
  const AvailableBalance._();

  const factory AvailableBalance({
    /// Efectivo en caja
    required double cashAmount,

    /// Saldo en cuentas bancarias
    required double bankAmount,

    /// Deudas inmediatas (tarjetas, cuentas por pagar)
    required double immediateDebts,

    /// Fecha del cálculo
    required DateTime calculatedAt,
  }) = _AvailableBalance;

  factory AvailableBalance.fromJson(Map<String, dynamic> json) =>
      _$AvailableBalanceFromJson(json);

  /// Total líquido disponible
  double get totalLiquid => cashAmount + bankAmount;

  /// Saldo disponible real = (Efectivo + Bancos) - Deudas Inmediatas
  double get available => totalLiquid - immediateDebts;

  /// Verifica si el saldo disponible es positivo
  bool get isPositive => available > 0;

  /// Verifica si el saldo disponible es negativo
  bool get isNegative => available < 0;

  /// Ratio de cobertura de deuda
  double get debtCoverageRatio {
    if (immediateDebts <= 0) return double.infinity;
    return totalLiquid / immediateDebts;
  }
}
