import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/database.dart';
import '../../domain/services/chart_service.dart';
import 'database_provider.dart';

// Re-export modelos para compatibilidad
export '../../domain/services/chart_service.dart';

part 'chart_provider.g.dart';

// ============================================================
// PROVIDER DEL SERVICIO
// ============================================================

/// Provider del servicio de gráficos
@riverpod
ChartService chartService(Ref ref) {
  return ChartService();
}

// ============================================================
// PROVIDERS DE DATOS
// ============================================================

/// Gastos por categoría para un mes específico
@riverpod
Future<List<CategoryExpenseData>> expensesByCategory(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final chartSvc = ref.watch(chartServiceProvider);

  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

  // Obtener datos en paralelo
  final results = await Future.wait([
    transactionsDao.getTransactionsInPeriod(startDate, endDate),
    categoriesDao.getAllCategories(),
  ]);

  return chartSvc.calculateExpensesByCategory(
    transactions: results[0] as List<TransactionEntry>,
    categories: results[1] as List<CategoryEntry>,
  );
}

/// Gastos del mes actual
@riverpod
Future<List<CategoryExpenseData>> currentMonthExpenses(Ref ref) async {
  final now = DateTime.now();
  return ref.watch(expensesByCategoryProvider(year: now.year, month: now.month).future);
}

/// Tendencia mensual de ingresos vs gastos
@riverpod
Future<List<MonthlyTrendData>> monthlyTrend(Ref ref, {int months = 6}) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final chartSvc = ref.watch(chartServiceProvider);
  final now = DateTime.now();

  // Obtener transacciones de cada mes
  final transactionsByMonth = <List<TransactionEntry>>[];
  final monthsList = <DateTime>[];

  for (var i = months - 1; i >= 0; i--) {
    final targetMonth = DateTime(now.year, now.month - i, 1);
    final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final transactions = await transactionsDao.getTransactionsInPeriod(monthStart, monthEnd);
    transactionsByMonth.add(transactions);
    monthsList.add(monthStart);
  }

  return chartSvc.calculateMonthlyTrend(
    transactionsByMonth: transactionsByMonth,
    months: monthsList,
  );
}

/// Comparativo mes actual vs anterior
@riverpod
Future<PeriodComparison> monthComparison(Ref ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final chartSvc = ref.watch(chartServiceProvider);
  final now = DateTime.now();

  // Rangos de fechas
  final currentStart = DateTime(now.year, now.month, 1);
  final currentEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final previousStart = DateTime(now.year, now.month - 1, 1);
  final previousEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

  // Obtener transacciones en paralelo
  final results = await Future.wait([
    transactionsDao.getTransactionsInPeriod(currentStart, currentEnd),
    transactionsDao.getTransactionsInPeriod(previousStart, previousEnd),
  ]);

  return chartSvc.calculateMonthComparison(
    currentMonthTransactions: results[0],
    previousMonthTransactions: results[1],
  );
}

/// Top N categorías de gasto del mes actual
@riverpod
Future<List<CategoryExpenseData>> topExpenseCategories(
  Ref ref, {
  int limit = 5,
}) async {
  final now = DateTime.now();
  final chartSvc = ref.watch(chartServiceProvider);
  final allExpenses = await ref.watch(
    expensesByCategoryProvider(year: now.year, month: now.month).future,
  );

  return chartSvc.getTopExpenseCategories(
    allExpenses: allExpenses,
    limit: limit,
  );
}
