import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mappers/reports_mappers.dart';
import '../../domain/services/reports_service.dart';
import 'database_provider.dart';

part 'reports_provider.g.dart';

/// Provider del servicio de reportes (ahora sin dependencias de DAOs)
@riverpod
ReportsService reportsService(Ref ref) {
  return ReportsService();
}

/// Provider para el Balance General
@riverpod
Future<BalanceSheet> balanceSheet(Ref ref) async {
  final accountsDao = ref.watch(accountsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final service = ref.watch(reportsServiceProvider);

  // Obtener datos
  final accounts = await accountsDao.getActiveAccounts();
  final categories = await categoriesDao.getAllCategories();

  // Convertir a DTOs y delegar al servicio
  return service.generateBalanceSheet(
    accounts: ReportsMappers.accountsToDtoList(accounts),
    categories: ReportsMappers.categoriesToDtoList(categories),
  );
}

/// Provider para el Estado de Resultados del mes actual
@riverpod
Future<IncomeStatement> currentMonthIncomeStatement(
  Ref ref,
) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final service = ref.watch(reportsServiceProvider);

  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Obtener datos
  final transactions =
      await transactionsDao.getTransactionsInPeriod(startDate, endDate);
  final categories = await categoriesDao.getAllCategories();

  // Convertir a DTOs y delegar al servicio
  return service.generateIncomeStatement(
    transactions: ReportsMappers.transactionsToDtoList(transactions),
    categories: ReportsMappers.categoriesToDtoList(categories),
    startDate: startDate,
    endDate: endDate,
  );
}

/// Provider para Estado de Resultados con período personalizado
@riverpod
Future<IncomeStatement> incomeStatementForPeriod(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final service = ref.watch(reportsServiceProvider);

  // Obtener datos
  final transactions =
      await transactionsDao.getTransactionsInPeriod(startDate, endDate);
  final categories = await categoriesDao.getAllCategories();

  // Convertir a DTOs y delegar al servicio
  return service.generateIncomeStatement(
    transactions: ReportsMappers.transactionsToDtoList(transactions),
    categories: ReportsMappers.categoriesToDtoList(categories),
    startDate: startDate,
    endDate: endDate,
  );
}

/// Provider para el Resumen Mensual actual
@riverpod
Future<MonthlySummary> currentMonthlySummary(Ref ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final service = ref.watch(reportsServiceProvider);

  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Obtener datos
  final transactions =
      await transactionsDao.getTransactionsInPeriod(startDate, endDate);
  final categories = await categoriesDao.getAllCategories();

  // Generar income statement primero
  final incomeStatement = service.generateIncomeStatement(
    transactions: ReportsMappers.transactionsToDtoList(transactions),
    categories: ReportsMappers.categoriesToDtoList(categories),
    startDate: startDate,
    endDate: endDate,
  );

  // Generar resumen mensual
  return service.generateMonthlySummary(
    incomeStatement: incomeStatement,
    transactionCount: transactions.length,
    year: now.year,
    month: now.month,
  );
}

/// Provider para Flujo de Efectivo del mes actual
@riverpod
Future<CashFlowReport> currentMonthCashFlow(Ref ref) async {
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final accountsDao = ref.watch(accountsDaoProvider);
  final service = ref.watch(reportsServiceProvider);

  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Obtener datos
  final transactions =
      await transactionsDao.getTransactionsInPeriod(startDate, endDate);
  final accounts = await accountsDao.getActiveAccounts();

  // Convertir a DTOs y delegar al servicio
  return service.generateCashFlowReport(
    transactions: ReportsMappers.transactionsToDtoList(transactions),
    accounts: ReportsMappers.accountsToDtoList(accounts),
    startDate: startDate,
    endDate: endDate,
  );
}

/// Provider para el período seleccionado en reportes
@riverpod
class ReportPeriod extends _$ReportPeriod {
  @override
  ReportDateRange build() {
    final now = DateTime.now();
    return ReportDateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  void setPeriod(ReportDateRange range) {
    state = range;
  }

  void setMonth(int year, int month) {
    state = ReportDateRange(
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 0),
    );
  }
}

/// Rango de fechas para reportes (evita conflicto con Flutter DateTimeRange)
class ReportDateRange {
  final DateTime start;
  final DateTime end;

  ReportDateRange({required this.start, required this.end});
}
