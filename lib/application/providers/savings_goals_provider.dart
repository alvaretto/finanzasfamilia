import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/savings_goals_dao.dart';
import '../../domain/entities/savings_goal.dart';
import 'database_provider.dart';

part 'savings_goals_provider.g.dart';

/// Provider del DAO de metas de ahorro
@riverpod
SavingsGoalsDao savingsGoalsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SavingsGoalsDao(db);
}

/// Provider de metas de ahorro activas (stream)
@riverpod
Stream<List<SavingsGoalEntry>> activeSavingsGoals(Ref ref) {
  final dao = ref.watch(savingsGoalsDaoProvider);
  return dao.watchActiveGoals();
}

/// Provider de metas en progreso (stream)
@riverpod
Stream<List<SavingsGoalEntry>> savingsGoalsInProgress(Ref ref) {
  final dao = ref.watch(savingsGoalsDaoProvider);
  return dao.watchGoalsInProgress();
}

/// Provider de contribuciones de una meta específica
@riverpod
Stream<List<SavingsContributionEntry>> savingsContributions(
  Ref ref,
  String goalId,
) {
  final dao = ref.watch(savingsGoalsDaoProvider);
  return dao.watchContributionsForGoal(goalId);
}

/// Convierte SavingsGoalEntry (Drift) a SavingsGoal (Domain)
SavingsGoal _entryToGoal(SavingsGoalEntry entry) {
  return SavingsGoal(
    id: entry.id,
    name: entry.name,
    description: entry.description,
    targetAmount: entry.targetAmount,
    currentAmount: entry.currentAmount,
    targetDate: entry.targetDate,
    accountId: entry.accountId,
    color: entry.color,
    icon: entry.icon,
    isActive: entry.isActive,
    isCompleted: entry.isCompleted,
    completedAt: entry.completedAt,
    createdAt: entry.createdAt,
    updatedAt: entry.updatedAt,
  );
}

/// Convierte SavingsContributionEntry (Drift) a SavingsContribution (Domain)
SavingsContribution _entryToContribution(SavingsContributionEntry entry) {
  return SavingsContribution(
    id: entry.id,
    goalId: entry.goalId,
    amount: entry.amount,
    note: entry.note,
    date: entry.date,
    createdAt: entry.createdAt,
  );
}

/// Notifier para gestionar metas de ahorro
@riverpod
class SavingsGoalsNotifier extends _$SavingsGoalsNotifier {
  @override
  Future<List<SavingsGoal>> build() async {
    final dao = ref.watch(savingsGoalsDaoProvider);
    final entries = await dao.getActiveGoals();
    return entries.map(_entryToGoal).toList();
  }

  /// Crea una nueva meta de ahorro
  Future<String> create({
    required String name,
    required double targetAmount,
    String? description,
    DateTime? targetDate,
    String? accountId,
    int color = 0xFF4CAF50,
    int icon = 0xe57f,
  }) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    final id = const Uuid().v4();
    final now = DateTime.now();

    await dao.insertGoal(SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      targetAmount: Value(targetAmount),
      currentAmount: const Value(0.0),
      targetDate: Value(targetDate),
      accountId: Value(accountId),
      color: Value(color),
      icon: Value(icon),
      isActive: const Value(true),
      isCompleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    ref.invalidateSelf();
    return id;
  }

  /// Actualiza una meta de ahorro
  Future<void> updateGoal({
    required String id,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
    String? accountId,
    int? color,
    int? icon,
  }) async {
    final dao = ref.read(savingsGoalsDaoProvider);

    await dao.updateGoal(SavingsGoalsCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      targetAmount: targetAmount != null ? Value(targetAmount) : const Value.absent(),
      targetDate: targetDate != null ? Value(targetDate) : const Value.absent(),
      accountId: accountId != null ? Value(accountId) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
      icon: icon != null ? Value(icon) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));

    ref.invalidateSelf();
  }

  /// Elimina una meta de ahorro
  Future<void> delete(String id) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    await dao.deleteGoal(id);
    ref.invalidateSelf();
  }

  /// Pausa una meta de ahorro
  Future<void> pause(String id) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    await dao.updateGoal(SavingsGoalsCompanion(
      id: Value(id),
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
    ref.invalidateSelf();
  }

  /// Reactiva una meta pausada
  Future<void> resume(String id) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    await dao.updateGoal(SavingsGoalsCompanion(
      id: Value(id),
      isActive: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
    ref.invalidateSelf();
  }

  /// Agrega una contribución a la meta
  Future<void> addContribution({
    required String goalId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    final id = const Uuid().v4();
    final contributionDate = date ?? DateTime.now();

    await dao.addContribution(SavingsContributionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      amount: Value(amount),
      note: Value(note),
      date: Value(contributionDate),
      createdAt: Value(DateTime.now()),
    ));

    ref.invalidateSelf();
  }

  /// Elimina una contribución
  Future<void> deleteContribution(String contributionId) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    await dao.deleteContribution(contributionId);
    ref.invalidateSelf();
  }

  /// Obtiene una meta por ID
  Future<SavingsGoal?> getById(String id) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    final entry = await dao.getGoalById(id);
    return entry != null ? _entryToGoal(entry) : null;
  }

  /// Obtiene contribuciones de una meta
  Future<List<SavingsContribution>> getContributions(String goalId) async {
    final dao = ref.read(savingsGoalsDaoProvider);
    final entries = await dao.getContributionsForGoal(goalId);
    return entries.map(_entryToContribution).toList();
  }
}

/// Provider de resumen de metas de ahorro
@riverpod
class SavingsGoalsSummary extends _$SavingsGoalsSummary {
  @override
  Future<SavingsGoalsSummaryData> build() async {
    final dao = ref.watch(savingsGoalsDaoProvider);
    final activeGoals = await dao.getActiveGoals();
    final completedGoals = await dao.getCompletedGoals();
    final inProgressGoals = await dao.getGoalsInProgress();

    final totalTargetAmount = activeGoals.fold(
      0.0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final totalCurrentAmount = activeGoals.fold(
      0.0,
      (sum, goal) => sum + goal.currentAmount,
    );

    return SavingsGoalsSummaryData(
      activeCount: activeGoals.length,
      completedCount: completedGoals.length,
      inProgressCount: inProgressGoals.length,
      totalTargetAmount: totalTargetAmount,
      totalCurrentAmount: totalCurrentAmount,
      overallProgress: totalTargetAmount > 0
          ? (totalCurrentAmount / totalTargetAmount) * 100
          : 0,
    );
  }
}

/// Datos del resumen de metas de ahorro
class SavingsGoalsSummaryData {
  final int activeCount;
  final int completedCount;
  final int inProgressCount;
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double overallProgress;

  const SavingsGoalsSummaryData({
    required this.activeCount,
    required this.completedCount,
    required this.inProgressCount,
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.overallProgress,
  });
}
