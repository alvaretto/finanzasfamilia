// Servicio de dominio para gestión de metas de ahorro.
// Contiene lógica de negocio pura, independiente de framework.

import 'package:uuid/uuid.dart';
import '../repositories/savings_goal_repository.dart';

/// Excepción para errores de metas de ahorro.
class SavingsGoalException implements Exception {
  final String message;
  const SavingsGoalException(this.message);

  @override
  String toString() => message;
}

/// Excepción cuando no se encuentra una meta.
class SavingsGoalNotFoundException extends SavingsGoalException {
  final String goalId;
  const SavingsGoalNotFoundException(this.goalId)
      : super('Meta de ahorro no encontrada: $goalId');
}

/// Excepción cuando la contribución es inválida.
class InvalidContributionException extends SavingsGoalException {
  const InvalidContributionException(super.message);
}

/// Servicio de dominio para metas de ahorro.
///
/// Gestiona la lógica de negocio para:
/// - CRUD de metas de ahorro
/// - Contribuciones a metas
/// - Cálculo de progreso y resúmenes
/// - Validaciones de negocio
class SavingsGoalsService {
  final SavingsGoalRepository _goalRepository;
  final SavingsContributionRepository _contributionRepository;
  final Uuid _uuid;

  SavingsGoalsService({
    required SavingsGoalRepository goalRepository,
    required SavingsContributionRepository contributionRepository,
    Uuid? uuid,
  })  : _goalRepository = goalRepository,
        _contributionRepository = contributionRepository,
        _uuid = uuid ?? const Uuid();

  // ==================== CONSULTAS ====================

  /// Obtiene todas las metas activas.
  Future<List<SavingsGoalData>> getActiveGoals() {
    return _goalRepository.getActiveGoals();
  }

  /// Obtiene todas las metas completadas.
  Future<List<SavingsGoalData>> getCompletedGoals() {
    return _goalRepository.getCompletedGoals();
  }

  /// Obtiene metas en progreso.
  Future<List<SavingsGoalData>> getGoalsInProgress() {
    return _goalRepository.getGoalsInProgress();
  }

  /// Obtiene una meta por ID.
  Future<SavingsGoalData?> getGoalById(String id) {
    return _goalRepository.getGoalById(id);
  }

  /// Obtiene contribuciones de una meta.
  Future<List<SavingsContributionData>> getContributions(String goalId) {
    return _contributionRepository.getContributionsForGoal(goalId);
  }

  /// Calcula el resumen de todas las metas.
  Future<SavingsGoalsSummaryData> calculateSummary() async {
    final activeGoals = await _goalRepository.getActiveGoals();
    final completedGoals = await _goalRepository.getCompletedGoals();
    final inProgressGoals = await _goalRepository.getGoalsInProgress();

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

  // ==================== COMANDOS ====================

  /// Crea una nueva meta de ahorro.
  ///
  /// Valida que:
  /// - El nombre no esté vacío
  /// - El monto objetivo sea positivo
  ///
  /// Retorna el ID de la meta creada.
  Future<String> createGoal(CreateSavingsGoalData data) async {
    _validateGoalData(data);

    final id = _uuid.v4();
    await _goalRepository.insertGoal(id, data);
    return id;
  }

  /// Actualiza una meta existente.
  Future<void> updateGoal(String id, UpdateSavingsGoalData data) async {
    final existing = await _goalRepository.getGoalById(id);
    if (existing == null) {
      throw SavingsGoalNotFoundException(id);
    }

    if (data.targetAmount != null && data.targetAmount! <= 0) {
      throw const SavingsGoalException(
        'El monto objetivo debe ser mayor a cero',
      );
    }

    await _goalRepository.updateGoal(id, data);
  }

  /// Elimina una meta y todas sus contribuciones.
  Future<void> deleteGoal(String id) async {
    final existing = await _goalRepository.getGoalById(id);
    if (existing == null) {
      throw SavingsGoalNotFoundException(id);
    }

    await _goalRepository.deleteGoal(id);
  }

  /// Pausa una meta activa.
  Future<void> pauseGoal(String id) async {
    final existing = await _goalRepository.getGoalById(id);
    if (existing == null) {
      throw SavingsGoalNotFoundException(id);
    }

    if (!existing.isActive) {
      throw const SavingsGoalException('La meta ya está pausada');
    }

    await _goalRepository.pauseGoal(id);
  }

  /// Reactiva una meta pausada.
  Future<void> resumeGoal(String id) async {
    final existing = await _goalRepository.getGoalById(id);
    if (existing == null) {
      throw SavingsGoalNotFoundException(id);
    }

    if (existing.isActive) {
      throw const SavingsGoalException('La meta ya está activa');
    }

    if (existing.isCompleted) {
      throw const SavingsGoalException(
        'No se puede reactivar una meta completada',
      );
    }

    await _goalRepository.activateGoal(id);
  }

  /// Agrega una contribución a una meta.
  ///
  /// Valida que:
  /// - La meta exista
  /// - La meta esté activa
  /// - El monto sea positivo
  ///
  /// Retorna el ID de la contribución.
  Future<String> addContribution({
    required String goalId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    final goal = await _goalRepository.getGoalById(goalId);
    if (goal == null) {
      throw SavingsGoalNotFoundException(goalId);
    }

    if (!goal.isActive) {
      throw const InvalidContributionException(
        'No se pueden agregar contribuciones a una meta pausada',
      );
    }

    if (goal.isCompleted) {
      throw const InvalidContributionException(
        'No se pueden agregar contribuciones a una meta completada',
      );
    }

    if (amount <= 0) {
      throw const InvalidContributionException(
        'El monto debe ser mayor a cero',
      );
    }

    final id = _uuid.v4();
    final contributionDate = date ?? DateTime.now();

    await _contributionRepository.addContribution(
      id: id,
      goalId: goalId,
      amount: amount,
      note: note,
      date: contributionDate,
    );

    return id;
  }

  /// Elimina una contribución.
  Future<void> deleteContribution(String contributionId) async {
    await _contributionRepository.deleteContribution(contributionId);
  }

  // ==================== VALIDACIONES ====================

  void _validateGoalData(CreateSavingsGoalData data) {
    if (data.name.trim().isEmpty) {
      throw const SavingsGoalException('El nombre de la meta es requerido');
    }

    if (data.targetAmount <= 0) {
      throw const SavingsGoalException(
        'El monto objetivo debe ser mayor a cero',
      );
    }

    if (data.targetDate != null && data.targetDate!.isBefore(DateTime.now())) {
      throw const SavingsGoalException(
        'La fecha objetivo debe ser futura',
      );
    }
  }

  // ==================== STREAMS ====================

  /// Stream de metas activas.
  Stream<List<SavingsGoalData>> watchActiveGoals() {
    return _goalRepository.watchActiveGoals();
  }

  /// Stream de metas en progreso.
  Stream<List<SavingsGoalData>> watchGoalsInProgress() {
    return _goalRepository.watchGoalsInProgress();
  }

  /// Stream de contribuciones de una meta.
  Stream<List<SavingsContributionData>> watchContributions(String goalId) {
    return _contributionRepository.watchContributionsForGoal(goalId);
  }
}
