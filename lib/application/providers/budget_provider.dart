import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/drift_budget_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/services/budget_service.dart';
import 'database_provider.dart';

// Re-exportar tipos del dominio para acceso desde presentation layer
export '../../domain/repositories/budget_repository.dart'
    show BudgetData, BudgetProgressData, BudgetStatus;

part 'budget_provider.g.dart';

// ============================================================
// PROVIDERS DE INFRAESTRUCTURA
// ============================================================

/// Provider del repositorio de presupuestos
@riverpod
BudgetRepository budgetRepository(Ref ref) {
  final dao = ref.watch(budgetsDaoProvider);
  return DriftBudgetRepository(dao);
}

/// Provider del repositorio de gastos por categoría
@riverpod
CategorySpendingRepository categorySpendingRepository(Ref ref) {
  final dao = ref.watch(transactionsDaoProvider);
  return DriftCategorySpendingRepository(dao);
}

/// Provider del servicio de presupuestos
@riverpod
BudgetService budgetService(Ref ref) {
  return BudgetService(
    budgetRepository: ref.watch(budgetRepositoryProvider),
    spendingRepository: ref.watch(categorySpendingRepositoryProvider),
  );
}

// ============================================================
// PROVIDERS DE CONSULTA
// ============================================================

/// Provider de presupuestos del mes actual
@riverpod
class CurrentMonthBudgets extends _$CurrentMonthBudgets {
  @override
  Future<List<BudgetData>> build() async {
    final service = ref.watch(budgetServiceProvider);
    return service.getCurrentMonthBudgets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(budgetServiceProvider);
      return service.getCurrentMonthBudgets();
    });
  }
}

/// Provider del progreso de un presupuesto específico
@riverpod
Future<BudgetProgressData?> budgetProgress(
  Ref ref,
  String categoryId,
) async {
  final service = ref.watch(budgetServiceProvider);
  return service.getBudgetProgress(categoryId);
}

/// Provider de todos los progresos de presupuesto del mes
@riverpod
Future<List<BudgetProgressData>> allBudgetProgress(Ref ref) async {
  final service = ref.watch(budgetServiceProvider);
  return service.getAllBudgetProgress();
}

// ============================================================
// NOTIFIER PRINCIPAL
// ============================================================

/// Notifier para operaciones CRUD de presupuestos
@riverpod
class BudgetsNotifier extends _$BudgetsNotifier {
  late int _month;
  late int _year;

  @override
  Future<List<BudgetData>> build(int month, int year) async {
    _month = month;
    _year = year;
    final service = ref.watch(budgetServiceProvider);
    return service.getBudgetsForMonth(month, year);
  }

  BudgetService get _service => ref.read(budgetServiceProvider);

  /// Crea un nuevo presupuesto
  Future<void> createBudget({
    required String categoryId,
    required double amount,
  }) async {
    await _service.createBudget(
      categoryId: categoryId,
      amount: amount,
      month: _month,
      year: _year,
    );
    ref.invalidateSelf();
  }

  /// Actualiza un presupuesto existente
  Future<void> updateBudget({
    required String id,
    required double amount,
  }) async {
    await _service.updateBudgetAmount(id, amount);
    ref.invalidateSelf();
  }

  /// Elimina un presupuesto
  Future<void> deleteBudget(String id) async {
    await _service.deleteBudget(id);
    ref.invalidateSelf();
  }

  /// Copia presupuestos del mes anterior al mes actual
  Future<int> copyFromPreviousMonth() async {
    final count = await _service.copyFromPreviousMonth(_month, _year);
    if (count > 0) {
      ref.invalidateSelf();
    }
    return count;
  }
}
