import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import 'database_provider.dart';

part 'budget_provider.g.dart';

/// Estado del progreso de un presupuesto
class BudgetProgress {
  final BudgetEntry budget;
  final double spent;
  final double percentage;
  final BudgetStatus status;

  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.percentage,
    required this.status,
  });

  /// Monto restante
  double get remaining => budget.amount - spent;
}

/// Estado del semáforo de presupuesto
enum BudgetStatus {
  /// Verde: < 80% del presupuesto
  safe,

  /// Amarillo: 80-99% del presupuesto
  warning,

  /// Rojo: >= 100% del presupuesto
  exceeded,
}

/// Notifier de presupuestos del mes actual
@riverpod
class CurrentMonthBudgets extends _$CurrentMonthBudgets {
  @override
  Future<List<BudgetEntry>> build() async {
    final dao = ref.watch(budgetsDaoProvider);
    final now = DateTime.now();
    return dao.getBudgetsForMonth(now.month, now.year);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dao = ref.read(budgetsDaoProvider);
      final now = DateTime.now();
      return dao.getBudgetsForMonth(now.month, now.year);
    });
  }
}

/// Notifier para operaciones CRUD de presupuestos
@riverpod
class BudgetsNotifier extends _$BudgetsNotifier {
  late int _month;
  late int _year;

  @override
  Future<List<BudgetEntry>> build(int month, int year) async {
    _month = month;
    _year = year;
    final dao = ref.watch(budgetsDaoProvider);
    return dao.getBudgetsForMonth(month, year);
  }

  /// Crea un nuevo presupuesto
  Future<void> createBudget({
    required String categoryId,
    required double amount,
  }) async {
    final dao = ref.read(budgetsDaoProvider);
    final now = DateTime.now();

    await dao.insertBudget(BudgetsCompanion.insert(
      id: const Uuid().v4(),
      categoryId: categoryId,
      amount: amount,
      month: _month,
      year: _year,
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    ref.invalidateSelf();
  }

  /// Actualiza un presupuesto existente
  Future<void> updateBudget({
    required String id,
    required double amount,
  }) async {
    final dao = ref.read(budgetsDaoProvider);
    final now = DateTime.now();

    await dao.updateBudget(BudgetsCompanion(
      id: Value(id),
      amount: Value(amount),
      updatedAt: Value(now),
    ));

    ref.invalidateSelf();
  }

  /// Elimina un presupuesto
  Future<void> deleteBudget(String id) async {
    final dao = ref.read(budgetsDaoProvider);
    await dao.deleteBudget(id);
    ref.invalidateSelf();
  }

  /// Copia presupuestos del mes anterior al mes actual
  Future<void> copyFromPreviousMonth() async {
    final dao = ref.read(budgetsDaoProvider);
    final now = DateTime.now();

    // Calcular mes anterior
    int prevMonth = _month - 1;
    int prevYear = _year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear -= 1;
    }

    // Obtener presupuestos del mes anterior
    final previousBudgets = await dao.getBudgetsForMonth(prevMonth, prevYear);

    // Crear presupuestos para el mes actual
    for (final budget in previousBudgets) {
      // Verificar si ya existe presupuesto para esta categoría
      final existing = await dao.getBudgetForCategory(
        budget.categoryId,
        _month,
        _year,
      );

      if (existing == null) {
        await dao.insertBudget(BudgetsCompanion.insert(
          id: const Uuid().v4(),
          categoryId: budget.categoryId,
          amount: budget.amount,
          month: _month,
          year: _year,
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
      }
    }

    ref.invalidateSelf();
  }
}

/// Provider del progreso de un presupuesto específico
@riverpod
Future<BudgetProgress?> budgetProgress(
  Ref ref,
  String categoryId,
) async {
  final budgetsDao = ref.watch(budgetsDaoProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Obtener presupuesto de la categoría
  final budget = await budgetsDao.getBudgetForCategory(
    categoryId,
    now.month,
    now.year,
  );

  if (budget == null) {
    return null;
  }

  // Calcular total gastado en la categoría
  final spent = await transactionsDao.getTotalByCategoryInPeriod(
    categoryId,
    startOfMonth,
    endOfMonth,
  );

  // Calcular porcentaje
  final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;

  // Determinar estado del semáforo
  final status = _calculateStatus(percentage);

  return BudgetProgress(
    budget: budget,
    spent: spent,
    percentage: percentage,
    status: status,
  );
}

/// Calcula el estado del semáforo basado en el porcentaje
BudgetStatus _calculateStatus(double percentage) {
  if (percentage >= 100) {
    return BudgetStatus.exceeded;
  } else if (percentage >= 80) {
    return BudgetStatus.warning;
  } else {
    return BudgetStatus.safe;
  }
}

/// Provider de todos los progresos de presupuesto del mes
@riverpod
Future<List<BudgetProgress>> allBudgetProgress(Ref ref) async {
  final budgetsDao = ref.watch(budgetsDaoProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final budgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
  final progressList = <BudgetProgress>[];

  for (final budget in budgets) {
    final spent = await transactionsDao.getTotalByCategoryInPeriod(
      budget.categoryId,
      startOfMonth,
      endOfMonth,
    );

    final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
    final status = _calculateStatus(percentage);

    progressList.add(BudgetProgress(
      budget: budget,
      spent: spent,
      percentage: percentage,
      status: status,
    ));
  }

  return progressList;
}
