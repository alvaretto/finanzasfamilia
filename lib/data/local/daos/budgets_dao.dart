import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/budgets_table.dart';

part 'budgets_dao.g.dart';

/// DAO para operaciones CRUD de presupuestos
@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  /// Obtiene todos los presupuestos activos
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<BudgetEntry>> getActiveBudgets() {
    return (select(budgets)
          ..where((b) => b.isActive.equals(true) | b.isActive.isNull()))
        .get();
  }

  /// Obtiene presupuesto de una categoría para un mes específico
  Future<BudgetEntry?> getBudgetForCategory(
    String categoryId,
    int month,
    int year,
  ) {
    return (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.month.equals(month) &
              b.year.equals(year)))
        .getSingleOrNull();
  }

  /// Obtiene todos los presupuestos de un mes
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<BudgetEntry>> getBudgetsForMonth(int month, int year) {
    return (select(budgets)
          ..where((b) =>
              b.month.equals(month) &
              b.year.equals(year) &
              (b.isActive.equals(true) | b.isActive.isNull())))
        .get();
  }

  /// Inserta un presupuesto
  Future<void> insertBudget(BudgetsCompanion budget) {
    return into(budgets).insert(budget);
  }

  /// Actualiza un presupuesto
  Future<bool> updateBudget(BudgetsCompanion budget) {
    return (update(budgets)..where((b) => b.id.equals(budget.id.value)))
        .write(budget)
        .then((rows) => rows > 0);
  }

  /// Elimina un presupuesto
  Future<int> deleteBudget(String id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  /// Stream de presupuestos del mes actual
  /// Considera isActive = NULL como activo (valor por defecto)
  Stream<List<BudgetEntry>> watchCurrentMonthBudgets() {
    final now = DateTime.now();
    return (select(budgets)
          ..where((b) =>
              b.month.equals(now.month) &
              b.year.equals(now.year) &
              (b.isActive.equals(true) | b.isActive.isNull())))
        .watch();
  }
}
