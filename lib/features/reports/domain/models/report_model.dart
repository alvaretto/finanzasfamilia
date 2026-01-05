/// Periodo de reporte
enum ReportPeriod {
  week,
  month,
  quarter,
  year,
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.week:
        return 'Semana';
      case ReportPeriod.month:
        return 'Mes';
      case ReportPeriod.quarter:
        return 'Trimestre';
      case ReportPeriod.year:
        return 'Año';
      case ReportPeriod.custom:
        return 'Personalizado';
    }
  }

  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (
          DateTime(start.year, start.month, start.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportPeriod.quarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(now.year, quarterStart, 1),
          DateTime(now.year, quarterStart + 3, 0, 23, 59, 59),
        );
      case ReportPeriod.year:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case ReportPeriod.custom:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
    }
  }
}

/// Datos de categoría para gráfico
class CategoryData {
  final String categoryId;
  final String name;
  final String? icon;
  final String? color;
  final double amount;
  final double percentage;

  const CategoryData({
    required this.categoryId,
    required this.name,
    this.icon,
    this.color,
    required this.amount,
    required this.percentage,
  });
}

/// Datos de flujo mensual
class MonthlyFlowData {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyFlowData({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}

/// Datos de tendencia diaria
class DailyTrendData {
  final DateTime date;
  final double amount;
  final double accumulated;

  const DailyTrendData({
    required this.date,
    required this.amount,
    required this.accumulated,
  });
}

/// Resumen de reporte
class ReportSummary {
  final double totalIncome;
  final double totalExpense;
  final double previousIncome;
  final double previousExpense;
  final List<CategoryData> topExpenseCategories;
  final List<CategoryData> topIncomeCategories;
  final List<MonthlyFlowData> monthlyFlow;
  final List<DailyTrendData> dailyTrend;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.previousIncome,
    required this.previousExpense,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
    required this.monthlyFlow,
    required this.dailyTrend,
  });

  double get balance => totalIncome - totalExpense;

  double get incomeChange {
    if (previousIncome == 0) return 0;
    return ((totalIncome - previousIncome) / previousIncome) * 100;
  }

  double get expenseChange {
    if (previousExpense == 0) return 0;
    return ((totalExpense - previousExpense) / previousExpense) * 100;
  }

  // Mayor cambio es positivo (menos gastos o más ingresos)
  bool get isIncomeChangePositive => incomeChange >= 0;
  bool get isExpenseChangePositive => expenseChange <= 0;
}
