import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/reports_service.dart';
import 'database_provider.dart';

part 'reports_provider.g.dart';

/// Provider del servicio de reportes
@riverpod
ReportsService reportsService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final accountsDao = ref.watch(accountsDaoProvider);
  final journalEntriesDao = ref.watch(journalEntriesDaoProvider);

  return ReportsService(
    db: db,
    transactionsDao: transactionsDao,
    categoriesDao: categoriesDao,
    accountsDao: accountsDao,
    journalEntriesDao: journalEntriesDao,
  );
}

/// Provider para el Balance General
@riverpod
Future<BalanceSheet> balanceSheet(Ref ref) async {
  final service = ref.watch(reportsServiceProvider);
  return service.generateBalanceSheet();
}

/// Provider para el Estado de Resultados del mes actual
@riverpod
Future<IncomeStatement> currentMonthIncomeStatement(
  Ref ref,
) async {
  final service = ref.watch(reportsServiceProvider);
  final now = DateTime.now();
  return service.generateIncomeStatement(
    startDate: DateTime(now.year, now.month, 1),
    endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
  );
}

/// Provider para Estado de Resultados con período personalizado
@riverpod
Future<IncomeStatement> incomeStatementForPeriod(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final service = ref.watch(reportsServiceProvider);
  return service.generateIncomeStatement(
    startDate: startDate,
    endDate: endDate,
  );
}

/// Provider para el Resumen Mensual actual
@riverpod
Future<MonthlySummary> currentMonthlySummary(Ref ref) async {
  final service = ref.watch(reportsServiceProvider);
  final now = DateTime.now();
  return service.generateMonthlySummary(
    year: now.year,
    month: now.month,
  );
}

/// Provider para Flujo de Efectivo del mes actual
@riverpod
Future<CashFlowReport> currentMonthCashFlow(Ref ref) async {
  final service = ref.watch(reportsServiceProvider);
  final now = DateTime.now();
  return service.generateCashFlowReport(
    startDate: DateTime(now.year, now.month, 1),
    endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
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
