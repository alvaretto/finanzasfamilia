/// Datos de un presupuesto.
class BudgetData {
  final String id;
  final String categoryId;
  final double amount;
  final int month;
  final int year;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetData({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Datos para crear un presupuesto.
class CreateBudgetData {
  final String categoryId;
  final double amount;
  final int month;
  final int year;

  const CreateBudgetData({
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
  });
}

/// Estado del semáforo de presupuesto.
enum BudgetStatus {
  /// Verde: < 80% del presupuesto
  safe,

  /// Amarillo: 80-99% del presupuesto
  warning,

  /// Rojo: >= 100% del presupuesto
  exceeded,
}

/// Progreso de un presupuesto.
class BudgetProgressData {
  final BudgetData budget;
  final double spent;
  final double percentage;
  final BudgetStatus status;

  const BudgetProgressData({
    required this.budget,
    required this.spent,
    required this.percentage,
    required this.status,
  });

  /// Monto restante.
  double get remaining => budget.amount - spent;
}

/// Interfaz del repositorio de presupuestos.
abstract class BudgetRepository {
  /// Obtiene todos los presupuestos activos.
  Future<List<BudgetData>> getActiveBudgets();

  /// Obtiene presupuestos de un mes específico.
  Future<List<BudgetData>> getBudgetsForMonth(int month, int year);

  /// Obtiene presupuesto de una categoría para un mes específico.
  Future<BudgetData?> getBudgetForCategory(
    String categoryId,
    int month,
    int year,
  );

  /// Crea un nuevo presupuesto.
  Future<void> createBudget(String id, CreateBudgetData data);

  /// Actualiza el monto de un presupuesto.
  Future<void> updateBudgetAmount(String id, double amount);

  /// Elimina un presupuesto.
  Future<void> deleteBudget(String id);

  /// Stream de presupuestos del mes actual.
  Stream<List<BudgetData>> watchCurrentMonthBudgets();
}

/// Interfaz para obtener gastos por categoría (para cálculo de progreso).
abstract class CategorySpendingRepository {
  /// Obtiene el total gastado en una categoría durante un período.
  Future<double> getTotalSpentInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  );
}
