import 'package:uuid/uuid.dart';

import '../repositories/budget_repository.dart';

/// Servicio de dominio para gestión de presupuestos.
///
/// Contiene la lógica de negocio para:
/// - CRUD de presupuestos
/// - Cálculo de progreso y estado semáforo
/// - Copia de presupuestos entre meses
class BudgetService {
  final BudgetRepository _budgetRepository;
  final CategorySpendingRepository _spendingRepository;

  BudgetService({
    required BudgetRepository budgetRepository,
    required CategorySpendingRepository spendingRepository,
  })  : _budgetRepository = budgetRepository,
        _spendingRepository = spendingRepository;

  // ============================================================
  // CONSULTAS
  // ============================================================

  /// Obtiene presupuestos del mes actual.
  Future<List<BudgetData>> getCurrentMonthBudgets() async {
    final now = DateTime.now();
    return _budgetRepository.getBudgetsForMonth(now.month, now.year);
  }

  /// Obtiene presupuestos de un mes específico.
  Future<List<BudgetData>> getBudgetsForMonth(int month, int year) {
    return _budgetRepository.getBudgetsForMonth(month, year);
  }

  /// Obtiene presupuesto de una categoría para el mes actual.
  Future<BudgetData?> getBudgetForCategory(String categoryId) async {
    final now = DateTime.now();
    return _budgetRepository.getBudgetForCategory(
      categoryId,
      now.month,
      now.year,
    );
  }

  /// Stream de presupuestos del mes actual.
  Stream<List<BudgetData>> watchCurrentMonthBudgets() {
    return _budgetRepository.watchCurrentMonthBudgets();
  }

  // ============================================================
  // PROGRESO
  // ============================================================

  /// Calcula el progreso de un presupuesto específico.
  Future<BudgetProgressData?> getBudgetProgress(String categoryId) async {
    final now = DateTime.now();
    final budget = await _budgetRepository.getBudgetForCategory(
      categoryId,
      now.month,
      now.year,
    );

    if (budget == null) return null;

    return _calculateProgress(budget, now);
  }

  /// Calcula el progreso de todos los presupuestos del mes actual.
  Future<List<BudgetProgressData>> getAllBudgetProgress() async {
    final now = DateTime.now();
    final budgets = await _budgetRepository.getBudgetsForMonth(
      now.month,
      now.year,
    );

    final progressList = <BudgetProgressData>[];
    for (final budget in budgets) {
      final progress = await _calculateProgress(budget, now);
      progressList.add(progress);
    }

    return progressList;
  }

  Future<BudgetProgressData> _calculateProgress(
    BudgetData budget,
    DateTime now,
  ) async {
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final spent = await _spendingRepository.getTotalSpentInPeriod(
      budget.categoryId,
      startOfMonth,
      endOfMonth,
    );

    final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
    final status = _calculateStatus(percentage);

    return BudgetProgressData(
      budget: budget,
      spent: spent,
      percentage: percentage,
      status: status,
    );
  }

  BudgetStatus _calculateStatus(double percentage) {
    if (percentage >= 100) {
      return BudgetStatus.exceeded;
    } else if (percentage >= 80) {
      return BudgetStatus.warning;
    } else {
      return BudgetStatus.safe;
    }
  }

  // ============================================================
  // OPERACIONES CRUD
  // ============================================================

  /// Crea un nuevo presupuesto.
  Future<void> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final id = const Uuid().v4();
    await _budgetRepository.createBudget(
      id,
      CreateBudgetData(
        categoryId: categoryId,
        amount: amount,
        month: month,
        year: year,
      ),
    );
  }

  /// Actualiza el monto de un presupuesto.
  Future<void> updateBudgetAmount(String id, double amount) {
    return _budgetRepository.updateBudgetAmount(id, amount);
  }

  /// Elimina un presupuesto.
  Future<void> deleteBudget(String id) {
    return _budgetRepository.deleteBudget(id);
  }

  /// Copia presupuestos del mes anterior al mes especificado.
  Future<int> copyFromPreviousMonth(int month, int year) async {
    // Calcular mes anterior
    int prevMonth = month - 1;
    int prevYear = year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear -= 1;
    }

    final previousBudgets = await _budgetRepository.getBudgetsForMonth(
      prevMonth,
      prevYear,
    );

    int copiedCount = 0;
    for (final budget in previousBudgets) {
      // Verificar si ya existe presupuesto para esta categoría
      final existing = await _budgetRepository.getBudgetForCategory(
        budget.categoryId,
        month,
        year,
      );

      if (existing == null) {
        await createBudget(
          categoryId: budget.categoryId,
          amount: budget.amount,
          month: month,
          year: year,
        );
        copiedCount++;
      }
    }

    return copiedCount;
  }
}
