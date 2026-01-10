import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/chart_service.dart';
import '../../data/local/daos/transactions_dao.dart';
import '../../data/local/daos/categories_dao.dart';
import 'database_provider.dart';

part 'chart_provider.g.dart';

@riverpod
ChartService chartService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ChartService(
    transactionsDao: TransactionsDao(db),
    categoriesDao: CategoriesDao(db),
  );
}

@riverpod
Future<List<CategoryExpenseData>> expensesByCategory(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final service = ref.watch(chartServiceProvider);
  return service.getExpensesByCategory(year: year, month: month);
}

@riverpod
Future<List<CategoryExpenseData>> currentMonthExpenses(Ref ref) async {
  final now = DateTime.now();
  final service = ref.watch(chartServiceProvider);
  return service.getExpensesByCategory(year: now.year, month: now.month);
}

@riverpod
Future<List<MonthlyTrendData>> monthlyTrend(Ref ref, {int months = 6}) async {
  final service = ref.watch(chartServiceProvider);
  return service.getMonthlyTrend(months: months);
}

@riverpod
Future<PeriodComparison> monthComparison(Ref ref) async {
  final service = ref.watch(chartServiceProvider);
  return service.getMonthComparison();
}

@riverpod
Future<List<CategoryExpenseData>> topExpenseCategories(
  Ref ref, {
  int limit = 5,
}) async {
  final now = DateTime.now();
  final service = ref.watch(chartServiceProvider);
  return service.getTopExpenseCategories(
    year: now.year,
    month: now.month,
    limit: limit,
  );
}
