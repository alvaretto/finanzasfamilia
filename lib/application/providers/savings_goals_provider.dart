import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/daos/savings_goals_dao.dart';
import '../../data/repositories/drift_savings_goal_repository.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../../domain/services/savings_goals_service.dart';
import 'database_provider.dart';

part 'savings_goals_provider.g.dart';

// ============================================================
// PROVIDERS DE INFRAESTRUCTURA
// ============================================================

/// Provider del DAO de metas de ahorro
@riverpod
SavingsGoalsDao savingsGoalsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SavingsGoalsDao(db);
}

/// Provider del repositorio de metas de ahorro
@riverpod
SavingsGoalRepository savingsGoalRepository(Ref ref) {
  final dao = ref.watch(savingsGoalsDaoProvider);
  return DriftSavingsGoalRepository(dao);
}

/// Provider del repositorio de contribuciones
@riverpod
SavingsContributionRepository savingsContributionRepository(Ref ref) {
  final dao = ref.watch(savingsGoalsDaoProvider);
  return DriftSavingsContributionRepository(dao);
}

/// Provider del servicio de metas de ahorro
@riverpod
SavingsGoalsService savingsGoalsService(Ref ref) {
  return SavingsGoalsService(
    goalRepository: ref.watch(savingsGoalRepositoryProvider),
    contributionRepository: ref.watch(savingsContributionRepositoryProvider),
  );
}

// ============================================================
// PROVIDERS DE DOMINIO (STREAMS)
// ============================================================

/// Provider de metas de ahorro activas (stream)
@riverpod
Stream<List<SavingsGoalData>> activeSavingsGoals(Ref ref) {
  final service = ref.watch(savingsGoalsServiceProvider);
  return service.watchActiveGoals();
}

/// Provider de metas en progreso (stream)
@riverpod
Stream<List<SavingsGoalData>> savingsGoalsInProgress(Ref ref) {
  final service = ref.watch(savingsGoalsServiceProvider);
  return service.watchGoalsInProgress();
}

/// Provider de contribuciones de una meta específica
@riverpod
Stream<List<SavingsContributionData>> savingsContributions(
  Ref ref,
  String goalId,
) {
  final service = ref.watch(savingsGoalsServiceProvider);
  return service.watchContributions(goalId);
}

// ============================================================
// NOTIFIER PRINCIPAL
// ============================================================

/// Notifier para gestionar metas de ahorro
/// Delega toda la lógica de negocio a SavingsGoalsService
@riverpod
class SavingsGoalsNotifier extends _$SavingsGoalsNotifier {
  @override
  Future<List<SavingsGoalData>> build() async {
    final service = ref.watch(savingsGoalsServiceProvider);
    return service.getActiveGoals();
  }

  SavingsGoalsService get _service => ref.read(savingsGoalsServiceProvider);

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
    final id = await _service.createGoal(CreateSavingsGoalData(
      name: name,
      description: description,
      targetAmount: targetAmount,
      targetDate: targetDate,
      accountId: accountId,
      color: color,
      icon: icon,
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
    await _service.updateGoal(
      id,
      UpdateSavingsGoalData(
        name: name,
        description: description,
        targetAmount: targetAmount,
        targetDate: targetDate,
        accountId: accountId,
        color: color,
        icon: icon,
      ),
    );

    ref.invalidateSelf();
  }

  /// Elimina una meta de ahorro
  Future<void> delete(String id) async {
    await _service.deleteGoal(id);
    ref.invalidateSelf();
  }

  /// Pausa una meta de ahorro
  Future<void> pause(String id) async {
    await _service.pauseGoal(id);
    ref.invalidateSelf();
  }

  /// Reactiva una meta pausada
  Future<void> resume(String id) async {
    await _service.resumeGoal(id);
    ref.invalidateSelf();
  }

  /// Agrega una contribución a la meta
  Future<void> addContribution({
    required String goalId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    await _service.addContribution(
      goalId: goalId,
      amount: amount,
      note: note,
      date: date,
    );

    ref.invalidateSelf();
  }

  /// Elimina una contribución
  Future<void> deleteContribution(String contributionId) async {
    await _service.deleteContribution(contributionId);
    ref.invalidateSelf();
  }

  /// Obtiene una meta por ID
  Future<SavingsGoalData?> getById(String id) async {
    return _service.getGoalById(id);
  }

  /// Obtiene contribuciones de una meta
  Future<List<SavingsContributionData>> getContributions(String goalId) async {
    return _service.getContributions(goalId);
  }
}

// ============================================================
// RESUMEN DE METAS
// ============================================================

/// Provider de resumen de metas de ahorro
@riverpod
class SavingsGoalsSummary extends _$SavingsGoalsSummary {
  @override
  Future<SavingsGoalsSummaryData> build() async {
    final service = ref.watch(savingsGoalsServiceProvider);
    return service.calculateSummary();
  }
}
