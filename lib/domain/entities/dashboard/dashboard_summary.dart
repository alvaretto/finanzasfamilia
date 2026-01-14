import 'budget_alert.dart';
import 'category_expense.dart';
import 'month_summary.dart';

/// Resumen completo del dashboard "¿Cómo Voy?"
class DashboardSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final double availableBalance;
  final List<CategoryExpense> expensesByCategory;
  final List<BudgetAlert> budgetAlerts;
  final MonthSummary currentMonth;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.availableBalance,
    required this.expensesByCategory,
    required this.budgetAlerts,
    required this.currentMonth,
  });
}
