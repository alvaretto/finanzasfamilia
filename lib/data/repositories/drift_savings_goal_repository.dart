import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/savings_goal_repository.dart';
import '../local/daos/savings_goals_dao.dart';
import '../local/database.dart';

/// Implementación Drift del repositorio de metas de ahorro.
class DriftSavingsGoalRepository implements SavingsGoalRepository {
  final SavingsGoalsDao _dao;

  DriftSavingsGoalRepository(this._dao);

  /// Obtiene el userId del usuario autenticado actual
  /// Retorna null si Supabase no está inicializado (en tests)
  String? get _currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SavingsGoalData>> getActiveGoals() async {
    final entries = await _dao.getActiveGoals();
    return entries.map(_toData).toList();
  }

  @override
  Future<List<SavingsGoalData>> getCompletedGoals() async {
    final entries = await _dao.getCompletedGoals();
    return entries.map(_toData).toList();
  }

  @override
  Future<List<SavingsGoalData>> getGoalsInProgress() async {
    final entries = await _dao.getGoalsInProgress();
    return entries.map(_toData).toList();
  }

  @override
  Future<SavingsGoalData?> getGoalById(String id) async {
    final entry = await _dao.getGoalById(id);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<void> insertGoal(String id, CreateSavingsGoalData data) async {
    final now = DateTime.now();
    await _dao.insertGoal(SavingsGoalsCompanion(
      id: Value(id),
      userId: Value(_currentUserId),
      name: Value(data.name),
      description: Value(data.description),
      targetAmount: Value(data.targetAmount),
      currentAmount: const Value(0.0),
      targetDate: Value(data.targetDate),
      accountId: Value(data.accountId),
      color: Value(data.color),
      icon: Value(data.icon),
      isActive: const Value(true),
      isCompleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  @override
  Future<void> updateGoal(String id, UpdateSavingsGoalData data) async {
    await _dao.updateGoal(SavingsGoalsCompanion(
      id: Value(id),
      name: data.name != null ? Value(data.name!) : const Value.absent(),
      description: data.description != null
          ? Value(data.description)
          : const Value.absent(),
      targetAmount: data.targetAmount != null
          ? Value(data.targetAmount!)
          : const Value.absent(),
      targetDate: data.targetDate != null
          ? Value(data.targetDate)
          : const Value.absent(),
      accountId: data.accountId != null
          ? Value(data.accountId)
          : const Value.absent(),
      color: data.color != null ? Value(data.color!) : const Value.absent(),
      icon: data.icon != null ? Value(data.icon!) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> deleteGoal(String id) => _dao.deleteGoal(id);

  @override
  Future<void> activateGoal(String id) async {
    await _dao.updateGoal(SavingsGoalsCompanion(
      id: Value(id),
      isActive: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> pauseGoal(String id) async {
    await _dao.updateGoal(SavingsGoalsCompanion(
      id: Value(id),
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Stream<List<SavingsGoalData>> watchActiveGoals() {
    return _dao.watchActiveGoals().map(
          (entries) => entries.map(_toData).toList(),
        );
  }

  @override
  Stream<List<SavingsGoalData>> watchGoalsInProgress() {
    return _dao.watchGoalsInProgress().map(
          (entries) => entries.map(_toData).toList(),
        );
  }

  SavingsGoalData _toData(SavingsGoalEntry entry) => SavingsGoalData(
        id: entry.id,
        name: entry.name,
        description: entry.description,
        targetAmount: entry.targetAmount,
        currentAmount: entry.currentAmount ?? 0.0,
        targetDate: entry.targetDate,
        accountId: entry.accountId,
        color: entry.color ?? 0xFF4CAF50,
        icon: entry.icon ?? 0xe57f,
        isActive: entry.isActive ?? true,
        isCompleted: entry.isCompleted ?? false,
        completedAt: entry.completedAt,
        createdAt: entry.createdAt ?? DateTime.now(),
        updatedAt: entry.updatedAt ?? DateTime.now(),
      );
}

/// Implementación Drift del repositorio de contribuciones.
class DriftSavingsContributionRepository implements SavingsContributionRepository {
  final SavingsGoalsDao _dao;

  DriftSavingsContributionRepository(this._dao);

  /// Obtiene el userId del usuario autenticado actual
  /// Retorna null si Supabase no está inicializado (en tests)
  String? get _currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SavingsContributionData>> getContributionsForGoal(
    String goalId,
  ) async {
    final entries = await _dao.getContributionsForGoal(goalId);
    return entries.map(_toData).toList();
  }

  @override
  Future<String> addContribution({
    required String id,
    required String goalId,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await _dao.addContribution(SavingsContributionsCompanion(
      id: Value(id),
      userId: Value(_currentUserId),
      goalId: Value(goalId),
      amount: Value(amount),
      note: Value(note),
      date: Value(date),
      createdAt: Value(DateTime.now()),
    ));
    return id;
  }

  @override
  Future<void> deleteContribution(String contributionId) {
    return _dao.deleteContribution(contributionId);
  }

  @override
  Stream<List<SavingsContributionData>> watchContributionsForGoal(
    String goalId,
  ) {
    return _dao.watchContributionsForGoal(goalId).map(
          (entries) => entries.map(_toData).toList(),
        );
  }

  SavingsContributionData _toData(SavingsContributionEntry entry) =>
      SavingsContributionData(
        id: entry.id,
        goalId: entry.goalId,
        amount: entry.amount,
        note: entry.note,
        date: entry.date,
        createdAt: entry.createdAt ?? DateTime.now(),
      );
}
