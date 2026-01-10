// Modelos de datos para gráficos financieros

/// Datos para gráfico de pie (gastos por categoría)
class CategoryExpenseData {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int color;

  const CategoryExpenseData({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

/// Datos para gráfico de línea (tendencia mensual)
class MonthlyTrendData {
  final DateTime month;
  final double income;
  final double expense;
  final double balance;

  const MonthlyTrendData({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
  });
}

/// Comparativo entre dos períodos
class PeriodComparison {
  final double currentIncome;
  final double previousIncome;
  final double incomeChange;
  final double incomeChangePercent;
  final double currentExpense;
  final double previousExpense;
  final double expenseChange;
  final double expenseChangePercent;

  const PeriodComparison({
    required this.currentIncome,
    required this.previousIncome,
    required this.incomeChange,
    required this.incomeChangePercent,
    required this.currentExpense,
    required this.previousExpense,
    required this.expenseChange,
    required this.expenseChangePercent,
  });
}
