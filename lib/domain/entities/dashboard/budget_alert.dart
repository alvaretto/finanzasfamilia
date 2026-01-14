import 'indicator_status.dart';

/// Alerta de presupuesto
class BudgetAlert {
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double percentage;
  final IndicatorStatus status;

  const BudgetAlert({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.percentage,
    required this.status,
  });

  bool get isOverBudget => percentage >= 100;
  bool get isWarning => percentage >= 80 && percentage < 100;
}
