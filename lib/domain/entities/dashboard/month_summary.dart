import 'expense_group.dart';

/// Resumen financiero de un mes
class MonthSummary {
  final int month;
  final int year;
  final double incomeTotal;
  final double expenseTotal;
  final double netBalance;
  final List<ExpenseGroup> expenseGroups;

  const MonthSummary({
    required this.month,
    required this.year,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.netBalance,
    required this.expenseGroups,
  });
}
