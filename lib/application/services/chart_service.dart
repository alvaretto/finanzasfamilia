import '../../data/local/daos/transactions_dao.dart';
import '../../data/local/daos/categories_dao.dart';

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

/// Servicio para cálculos de gráficos financieros
class ChartService {
  final TransactionsDao _transactionsDao;
  final CategoriesDao _categoriesDao;

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

  ChartService({
    required TransactionsDao transactionsDao,
    required CategoriesDao categoriesDao,
  })  : _transactionsDao = transactionsDao,
        _categoriesDao = categoriesDao;

  /// Obtiene gastos agrupados por categoría para un mes
  Future<List<CategoryExpenseData>> getExpensesByCategory({
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Obtener transacciones de gasto del mes
    final transactions = await _transactionsDao.getTransactionsInPeriod(
      startDate,
      endDate,
    );

    // Filtrar solo gastos
    final expenses = transactions.where((t) => t.type == 'expense').toList();

    // Agrupar por categoría
    final Map<String, double> categoryTotals = {};
    for (final tx in expenses) {
      final categoryId = tx.categoryId;
      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0) + tx.amount;
    }

    if (categoryTotals.isEmpty) return [];

    // Calcular total para porcentajes
    final total = categoryTotals.values.fold(0.0, (sum, v) => sum + v);

    // Obtener nombres de categorías y construir resultado
    final result = <CategoryExpenseData>[];
    var colorIndex = 0;

    for (final entry in categoryTotals.entries) {
      final category = await _categoriesDao.getCategoryById(entry.key);
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

  /// Obtiene tendencia de ingresos vs gastos de los últimos N meses
  Future<List<MonthlyTrendData>> getMonthlyTrend({int months = 6}) async {
    final now = DateTime.now();
    final result = <MonthlyTrendData>[];

    for (var i = months - 1; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
      final monthEnd =
          DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

      final transactions = await _transactionsDao.getTransactionsInPeriod(
        monthStart,
        monthEnd,
      );

      double income = 0;
      double expense = 0;

      for (final tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }

      result.add(MonthlyTrendData(
        month: monthStart,
        income: income,
        expense: expense,
        balance: income - expense,
      ));
    }

    return result;
  }

  /// Compara el mes actual con el mes anterior
  Future<PeriodComparison> getMonthComparison() async {
    final now = DateTime.now();

    // Mes actual
    final currentStart = DateTime(now.year, now.month, 1);
    final currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Mes anterior
    final previousStart = DateTime(now.year, now.month - 1, 1);
    final previousEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    // Obtener transacciones de ambos meses
    final currentTx = await _transactionsDao.getTransactionsInPeriod(
      currentStart,
      currentEnd,
    );
    final previousTx = await _transactionsDao.getTransactionsInPeriod(
      previousStart,
      previousEnd,
    );

    // Calcular totales mes actual
    double currentIncome = 0;
    double currentExpense = 0;
    for (final tx in currentTx) {
      if (tx.type == 'income') {
        currentIncome += tx.amount;
      } else if (tx.type == 'expense') {
        currentExpense += tx.amount;
      }
    }

    // Calcular totales mes anterior
    double previousIncome = 0;
    double previousExpense = 0;
    for (final tx in previousTx) {
      if (tx.type == 'income') {
        previousIncome += tx.amount;
      } else if (tx.type == 'expense') {
        previousExpense += tx.amount;
      }
    }

    // Calcular cambios
    final incomeChange = currentIncome - previousIncome;
    final expenseChange = currentExpense - previousExpense;

    return PeriodComparison(
      currentIncome: currentIncome,
      previousIncome: previousIncome,
      incomeChange: incomeChange,
      incomeChangePercent:
          previousIncome > 0 ? (incomeChange / previousIncome) * 100 : 0,
      currentExpense: currentExpense,
      previousExpense: previousExpense,
      expenseChange: expenseChange,
      expenseChangePercent:
          previousExpense > 0 ? (expenseChange / previousExpense) * 100 : 0,
    );
  }

  /// Obtiene los top N gastos por categoría
  Future<List<CategoryExpenseData>> getTopExpenseCategories({
    required int year,
    required int month,
    int limit = 5,
  }) async {
    final allExpenses = await getExpensesByCategory(year: year, month: month);
    return allExpenses.take(limit).toList();
  }
}
