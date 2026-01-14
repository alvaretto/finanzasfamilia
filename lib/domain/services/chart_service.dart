import '../entities/charts/chart_models.dart';
import '../entities/dashboard/dashboard.dart';

// Re-export modelos para compatibilidad
export '../entities/charts/chart_models.dart';

/// Servicio de dominio para cálculos de gráficos financieros.
/// Contiene lógica de negocio pura para visualizaciones.
class ChartService {
  // Colores predefinidos para categorías (Material Design)
  static const List<int> categoryColors = [
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFFFEB3B, // Yellow
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFFE91E63, // Pink
    0xFF3F51B5, // Indigo
    0xFF009688, // Teal
  ];

  /// Calcula gastos agrupados por categoría para un mes.
  /// Retorna lista ordenada por monto descendente.
  List<CategoryExpenseData> calculateExpensesByCategory({
    required List<TransactionSummaryDto> transactions,
    required List<CategoryInfoDto> categories,
  }) {
    // Filtrar solo gastos
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return [];

    // Agrupar por categoría
    final categoryTotals = <String, double>{};
    for (final tx in expenses) {
      categoryTotals[tx.categoryId] =
          (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
    }

    // Calcular total para porcentajes
    final total = categoryTotals.values.fold(0.0, (sum, v) => sum + v);

    // Crear mapa de categorías para lookup rápido
    final categoryMap = {for (var c in categories) c.id: c};

    // Construir resultado
    final result = <CategoryExpenseData>[];
    var colorIndex = 0;

    for (final entry in categoryTotals.entries) {
      final category = categoryMap[entry.key];
      final categoryName = category?.name ?? 'Sin categoría';

      result.add(CategoryExpenseData(
        categoryId: entry.key,
        categoryName: categoryName,
        amount: entry.value,
        percentage: total > 0 ? (entry.value / total) * 100 : 0,
        color: categoryColors[colorIndex % categoryColors.length],
      ));
      colorIndex++;
    }

    // Ordenar por monto descendente
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  /// Calcula tendencia mensual de ingresos vs gastos.
  /// Retorna lista de N meses ordenada cronológicamente.
  List<MonthlyTrendData> calculateMonthlyTrend({
    required List<List<TransactionSummaryDto>> transactionsByMonth,
    required List<DateTime> months,
  }) {
    final result = <MonthlyTrendData>[];

    for (var i = 0; i < months.length; i++) {
      final transactions = transactionsByMonth[i];
      final totals = _calculateMonthlyTotals(transactions);

      result.add(MonthlyTrendData(
        month: months[i],
        income: totals.income,
        expense: totals.expense,
        balance: totals.income - totals.expense,
      ));
    }

    return result;
  }

  /// Calcula comparativo entre mes actual y anterior.
  PeriodComparison calculateMonthComparison({
    required List<TransactionSummaryDto> currentMonthTransactions,
    required List<TransactionSummaryDto> previousMonthTransactions,
  }) {
    final current = _calculateMonthlyTotals(currentMonthTransactions);
    final previous = _calculateMonthlyTotals(previousMonthTransactions);

    final incomeChange = current.income - previous.income;
    final expenseChange = current.expense - previous.expense;

    return PeriodComparison(
      currentIncome: current.income,
      previousIncome: previous.income,
      incomeChange: incomeChange,
      incomeChangePercent:
          previous.income > 0 ? (incomeChange / previous.income) * 100 : 0,
      currentExpense: current.expense,
      previousExpense: previous.expense,
      expenseChange: expenseChange,
      expenseChangePercent:
          previous.expense > 0 ? (expenseChange / previous.expense) * 100 : 0,
    );
  }

  /// Obtiene los top N gastos por categoría.
  List<CategoryExpenseData> getTopExpenseCategories({
    required List<CategoryExpenseData> allExpenses,
    int limit = 5,
  }) {
    return allExpenses.take(limit).toList();
  }

  // ============================================================
  // MÉTODOS PRIVADOS
  // ============================================================

  _MonthlyTotals _calculateMonthlyTotals(
      List<TransactionSummaryDto> transactions) {
    double income = 0;
    double expense = 0;

    for (final tx in transactions) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else if (tx.type == 'expense') {
        expense += tx.amount;
      }
    }

    return _MonthlyTotals(income: income, expense: expense);
  }
}

/// Clase auxiliar interna para totales mensuales
class _MonthlyTotals {
  final double income;
  final double expense;

  const _MonthlyTotals({required this.income, required this.expense});
}
