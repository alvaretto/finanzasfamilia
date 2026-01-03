import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/report_model.dart';

/// Repositorio de reportes
class ReportRepository {
  final AppDatabase _db;

  ReportRepository({AppDatabase? database}) : _db = database ?? AppDatabase();

  /// Obtener resumen de reporte para un periodo
  Future<ReportSummary> getReportSummary(
    String userId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // Periodo anterior para comparación
    final periodDuration = toDate.difference(fromDate);
    final previousFrom = fromDate.subtract(periodDuration);
    final previousTo = fromDate.subtract(const Duration(days: 1));

    // Obtener totales del periodo actual
    final currentTotals = await _getTotalsByType(userId, fromDate, toDate);

    // Obtener totales del periodo anterior
    final previousTotals = await _getTotalsByType(userId, previousFrom, previousTo);

    // Top categorías de gasto
    final topExpenses = await _getTopCategories(userId, 'expense', fromDate, toDate);

    // Top categorías de ingreso
    final topIncome = await _getTopCategories(userId, 'income', fromDate, toDate);

    // Flujo mensual (últimos 6 meses)
    final monthlyFlow = await _getMonthlyFlow(userId);

    // Tendencia diaria del periodo
    final dailyTrend = await _getDailyTrend(userId, fromDate, toDate);

    return ReportSummary(
      totalIncome: currentTotals['income'] ?? 0,
      totalExpense: currentTotals['expense'] ?? 0,
      previousIncome: previousTotals['income'] ?? 0,
      previousExpense: previousTotals['expense'] ?? 0,
      topExpenseCategories: topExpenses,
      topIncomeCategories: topIncome,
      monthlyFlow: monthlyFlow,
      dailyTrend: dailyTrend,
    );
  }

  /// Obtener totales por tipo
  Future<Map<String, double>> _getTotalsByType(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.date.isBiggerOrEqualValue(from) &
          t.date.isSmallerOrEqualValue(to));

    final results = await query.get();
    final totals = <String, double>{'income': 0, 'expense': 0, 'transfer': 0};

    for (final tx in results) {
      totals[tx.type] = (totals[tx.type] ?? 0) + tx.amount;
    }

    return totals;
  }

  /// Obtener top categorías
  Future<List<CategoryData>> _getTopCategories(
    String userId,
    String type,
    DateTime from,
    DateTime to, {
    int limit = 5,
  }) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
    ])
      ..where(_db.transactions.userId.equals(userId) &
          _db.transactions.type.equals(type) &
          _db.transactions.date.isBiggerOrEqualValue(from) &
          _db.transactions.date.isSmallerOrEqualValue(to));

    final results = await query.get();

    // Agrupar por categoría
    final categoryAmounts = <int, _CategoryAggregation>{};
    double total = 0;

    for (final row in results) {
      final tx = row.readTable(_db.transactions);
      final cat = row.readTableOrNull(_db.categories);
      final catId = tx.categoryId ?? 0;

      total += tx.amount;

      if (!categoryAmounts.containsKey(catId)) {
        categoryAmounts[catId] = _CategoryAggregation(
          id: catId,
          name: cat?.name ?? 'Sin categoría',
          icon: cat?.icon,
          color: cat?.color,
          amount: 0,
        );
      }
      categoryAmounts[catId]!.amount += tx.amount;
    }

    // Convertir a lista y ordenar
    final sortedCategories = categoryAmounts.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Tomar los top y calcular porcentajes
    return sortedCategories.take(limit).map((cat) {
      return CategoryData(
        categoryId: cat.id,
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        amount: cat.amount,
        percentage: total > 0 ? (cat.amount / total) * 100 : 0,
      );
    }).toList();
  }

  /// Obtener flujo mensual (últimos 6 meses)
  Future<List<MonthlyFlowData>> _getMonthlyFlow(String userId) async {
    final now = DateTime.now();
    final flows = <MonthlyFlowData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final query = _db.select(_db.transactions)
        ..where((t) =>
            t.userId.equals(userId) &
            t.date.isBiggerOrEqualValue(month) &
            t.date.isSmallerThanValue(nextMonth));

      final results = await query.get();

      double income = 0;
      double expense = 0;

      for (final tx in results) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }

      flows.add(MonthlyFlowData(
        month: month,
        income: income,
        expense: expense,
      ));
    }

    return flows;
  }

  /// Obtener tendencia diaria
  Future<List<DailyTrendData>> _getDailyTrend(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.type.equals('expense') &
          t.date.isBiggerOrEqualValue(from) &
          t.date.isSmallerOrEqualValue(to))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    final results = await query.get();

    // Agrupar por día
    final dailyAmounts = <DateTime, double>{};
    for (final tx in results) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      dailyAmounts[day] = (dailyAmounts[day] ?? 0) + tx.amount;
    }

    // Crear lista con acumulado
    final trend = <DailyTrendData>[];
    double accumulated = 0;

    // Generar todos los días del periodo
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    while (!current.isAfter(end)) {
      final amount = dailyAmounts[current] ?? 0;
      accumulated += amount;

      trend.add(DailyTrendData(
        date: current,
        amount: amount,
        accumulated: accumulated,
      ));

      current = current.add(const Duration(days: 1));
    }

    return trend;
  }

  /// Obtener balance por cuenta
  Future<List<({String accountId, String name, double balance})>> getBalanceByAccount(
    String userId,
  ) async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.balance)]);

    final results = await query.get();

    return results.map((acc) => (
      accountId: acc.id,
      name: acc.name,
      balance: acc.balance,
    )).toList();
  }

  /// Obtener gastos por día de la semana
  Future<List<({int dayOfWeek, String name, double amount})>> getExpensesByDayOfWeek(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.type.equals('expense') &
          t.date.isBiggerOrEqualValue(from) &
          t.date.isSmallerOrEqualValue(to));

    final results = await query.get();

    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayAmounts = List.filled(7, 0.0);

    for (final tx in results) {
      final dayIndex = tx.date.weekday - 1; // 0-6
      dayAmounts[dayIndex] += tx.amount;
    }

    return List.generate(7, (i) => (
      dayOfWeek: i + 1,
      name: dayNames[i],
      amount: dayAmounts[i],
    ));
  }
}

class _CategoryAggregation {
  final int id;
  final String name;
  final String? icon;
  final String? color;
  double amount;

  _CategoryAggregation({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.amount,
  });
}
