import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/savings_goals_table.dart';

part 'savings_goals_dao.g.dart';

/// DAO para operaciones CRUD de metas de ahorro
@DriftAccessor(tables: [SavingsGoals, SavingsContributions])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  // ==================== SAVINGS GOALS ====================

  /// Obtiene todas las metas activas
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<SavingsGoalEntry>> getActiveGoals() {
    return (select(savingsGoals)
          ..where((g) => g.isActive.equals(true) | g.isActive.isNull())
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .get();
  }

  /// Obtiene una meta por ID
  Future<SavingsGoalEntry?> getGoalById(String id) {
    return (select(savingsGoals)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtiene metas completadas
  Future<List<SavingsGoalEntry>> getCompletedGoals() {
    return (select(savingsGoals)
          ..where((g) => g.isCompleted.equals(true))
          ..orderBy([(g) => OrderingTerm.desc(g.completedAt)]))
        .get();
  }

  /// Obtiene metas en progreso (activas y no completadas)
  /// Considera isActive = NULL como activo e isCompleted = NULL como no completado
  Future<List<SavingsGoalEntry>> getGoalsInProgress() {
    return (select(savingsGoals)
          ..where((g) =>
              (g.isActive.equals(true) | g.isActive.isNull()) &
              (g.isCompleted.equals(false) | g.isCompleted.isNull()))
          ..orderBy([(g) => OrderingTerm.asc(g.targetDate)]))
        .get();
  }

  /// Inserta una meta
  Future<void> insertGoal(SavingsGoalsCompanion goal) {
    return into(savingsGoals).insert(goal);
  }

  /// Actualiza una meta
  Future<bool> updateGoal(SavingsGoalsCompanion goal) {
    return (update(savingsGoals)..where((g) => g.id.equals(goal.id.value)))
        .write(goal)
        .then((rows) => rows > 0);
  }

  /// Elimina una meta y sus contribuciones
  Future<void> deleteGoal(String id) async {
    await (delete(savingsContributions)..where((c) => c.goalId.equals(id)))
        .go();
    await (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  /// Actualiza el monto actual de una meta
  Future<void> updateCurrentAmount(String goalId, double newAmount) async {
    await (update(savingsGoals)..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(
        currentAmount: Value(newAmount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marca una meta como completada
  Future<void> markAsCompleted(String goalId) async {
    await (update(savingsGoals)..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Stream de todas las metas activas
  /// Considera isActive = NULL como activo (valor por defecto)
  Stream<List<SavingsGoalEntry>> watchActiveGoals() {
    return (select(savingsGoals)
          ..where((g) => g.isActive.equals(true) | g.isActive.isNull())
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  /// Stream de metas en progreso
  /// Considera isActive = NULL como activo e isCompleted = NULL como no completado
  Stream<List<SavingsGoalEntry>> watchGoalsInProgress() {
    return (select(savingsGoals)
          ..where((g) =>
              (g.isActive.equals(true) | g.isActive.isNull()) &
              (g.isCompleted.equals(false) | g.isCompleted.isNull()))
          ..orderBy([(g) => OrderingTerm.asc(g.targetDate)]))
        .watch();
  }

  // ==================== CONTRIBUTIONS ====================

  /// Obtiene contribuciones de una meta
  Future<List<SavingsContributionEntry>> getContributionsForGoal(
      String goalId) {
    return (select(savingsContributions)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .get();
  }

  /// Inserta una contribución y actualiza el monto de la meta
  Future<void> addContribution(SavingsContributionsCompanion contribution) async {
    await into(savingsContributions).insert(contribution);

    // Recalcular el monto actual de la meta
    final goalId = contribution.goalId.value;
    final contributions = await getContributionsForGoal(goalId);
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    await updateCurrentAmount(goalId, total);

    // Verificar si se completó la meta
    final goal = await getGoalById(goalId);
    if (goal != null && total >= goal.targetAmount && !(goal.isCompleted ?? false)) {
      await markAsCompleted(goalId);
    }
  }

  /// Elimina una contribución y actualiza el monto de la meta
  Future<void> deleteContribution(String contributionId) async {
    final contribution = await (select(savingsContributions)
          ..where((c) => c.id.equals(contributionId)))
        .getSingleOrNull();

    if (contribution == null) return;

    final goalId = contribution.goalId;
    await (delete(savingsContributions)..where((c) => c.id.equals(contributionId)))
        .go();

    // Recalcular el monto actual de la meta
    final contributions = await getContributionsForGoal(goalId);
    final total = contributions.fold(0.0, (sum, c) => sum + c.amount);
    await updateCurrentAmount(goalId, total);
  }

  /// Stream de contribuciones de una meta
  Stream<List<SavingsContributionEntry>> watchContributionsForGoal(
      String goalId) {
    return (select(savingsContributions)
          ..where((c) => c.goalId.equals(goalId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }
}
