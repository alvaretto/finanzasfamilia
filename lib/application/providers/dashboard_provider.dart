import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/database.dart';
import '../../data/mappers/dashboard_mappers.dart';
import '../../domain/entities/dashboard/dashboard.dart';
import '../../domain/services/dashboard_service.dart';
import 'database_provider.dart';

// Re-export de entidades para compatibilidad
export '../../domain/entities/dashboard/dashboard.dart';

part 'dashboard_provider.g.dart';

// ============================================================
// PROVIDER DEL SERVICIO DE DASHBOARD
// ============================================================

/// Provider del servicio de cálculos del dashboard
@riverpod
DashboardService dashboardService(Ref ref) {
  return DashboardService();
}

// ============================================================
// PROVIDERS DE DATOS
// ============================================================

/// Provider del resumen del dashboard
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  try {
    debugPrint('[DASHBOARD] Iniciando carga...');
    final db = ref.watch(appDatabaseProvider);
    final categoriesDao = ref.watch(categoriesDaoProvider);
    final transactionsDao = ref.watch(transactionsDaoProvider);
    final budgetsDao = ref.watch(budgetsDaoProvider);
    final dashboardSvc = ref.watch(dashboardServiceProvider);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    debugPrint('[DASHBOARD] Obteniendo datos...');
    // Obtener datos necesarios en paralelo
    final results = await Future.wait([
      db.select(db.accounts).get(),
      categoriesDao.getAllCategories(),
      transactionsDao.getTransactionsInPeriod(startOfMonth, endOfMonth),
      budgetsDao.getBudgetsForMonth(now.month, now.year),
    ]);

    final accounts = results[0] as List<AccountEntry>;
    final categories = results[1] as List<CategoryEntry>;
    final monthTransactions = results[2] as List<TransactionEntry>;
    final budgets = results[3] as List<BudgetEntry>;

    debugPrint('[DASHBOARD] Cuentas: ${accounts.length}, Categorías: ${categories.length}');
    debugPrint('[DASHBOARD] Transacciones: ${monthTransactions.length}, Presupuestos: ${budgets.length}');

    // Calcular gastos por categoría de presupuesto
    final spentByBudgetCategory = <String, double>{};
    for (final budget in budgets) {
      final spent = await transactionsDao.getTotalByCategoryInPeriod(
        budget.categoryId,
        startOfMonth,
        endOfMonth,
      );
      spentByBudgetCategory[budget.categoryId] = spent;
    }

    debugPrint('[DASHBOARD] Calculando resumen...');
    // Convertir a DTOs y delegar cálculos al servicio de dominio
    final summary = dashboardSvc.calculateDashboardSummary(
      accounts: DashboardMappers.accountsToDtoList(accounts),
      categories: DashboardMappers.categoriesToDtoList(categories),
      monthTransactions: DashboardMappers.transactionsToDtoList(monthTransactions),
      budgets: DashboardMappers.budgetsToDtoList(budgets),
      spentByBudgetCategory: spentByBudgetCategory,
      now: now,
    );
    debugPrint('[DASHBOARD] Resumen calculado OK');
    return summary;
  } catch (e, stack) {
    debugPrint('[DASHBOARD ERROR] $e');
    debugPrint('[DASHBOARD STACK] $stack');
    rethrow;
  }
}

/// Provider del resumen de un mes específico
@riverpod
Future<MonthSummary> monthSummary(
  Ref ref,
  int month,
  int year,
) async {
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final dashboardSvc = ref.watch(dashboardServiceProvider);

  final startOfMonth = DateTime(year, month, 1);
  final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

  // Obtener datos en paralelo
  final results = await Future.wait([
    categoriesDao.getAllCategories(),
    transactionsDao.getTransactionsInPeriod(startOfMonth, endOfMonth),
  ]);

  final categories = results[0] as List<CategoryEntry>;
  final transactions = results[1] as List<TransactionEntry>;

  // Convertir a DTOs y delegar cálculos al servicio de dominio
  return dashboardSvc.calculateMonthSummary(
    transactions: DashboardMappers.transactionsToDtoList(transactions),
    categories: DashboardMappers.categoriesToDtoList(categories),
    month: month,
    year: year,
  );
}
