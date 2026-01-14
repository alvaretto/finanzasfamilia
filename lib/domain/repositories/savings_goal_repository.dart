// Interface de repositorio para metas de ahorro.
// Define operaciones CRUD y consultas para metas y contribuciones.

/// Datos de una meta de ahorro en el dominio.
class SavingsGoalData {
  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? accountId;
  final int color;
  final int icon;
  final bool isActive;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoalData({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.accountId,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Progreso como porcentaje (0-100).
  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

  /// Monto restante para alcanzar la meta.
  double get remainingAmount =>
      targetAmount > currentAmount ? targetAmount - currentAmount : 0;

  /// Días restantes hasta la fecha objetivo.
  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    if (targetDate!.isBefore(now)) return 0;
    return targetDate!.difference(now).inDays;
  }

  /// Ahorro diario necesario para alcanzar la meta a tiempo.
  double? get dailySavingsNeeded {
    final days = daysRemaining;
    if (days == null || days <= 0 || remainingAmount <= 0) return null;
    return remainingAmount / days;
  }

  /// Estado de la meta.
  SavingsGoalStatus get status {
    if (isCompleted) return SavingsGoalStatus.completed;
    if (!isActive) return SavingsGoalStatus.paused;
    if (targetDate != null && DateTime.now().isAfter(targetDate!)) {
      return SavingsGoalStatus.overdue;
    }
    return SavingsGoalStatus.inProgress;
  }
}

/// Estados posibles de una meta de ahorro.
enum SavingsGoalStatus {
  inProgress,
  completed,
  paused,
  overdue,
}

/// Datos de una contribución a una meta.
class SavingsContributionData {
  final String id;
  final String goalId;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const SavingsContributionData({
    required this.id,
    required this.goalId,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });
}

/// Datos para crear una meta de ahorro.
class CreateSavingsGoalData {
  final String name;
  final String? description;
  final double targetAmount;
  final DateTime? targetDate;
  final String? accountId;
  final int color;
  final int icon;

  const CreateSavingsGoalData({
    required this.name,
    this.description,
    required this.targetAmount,
    this.targetDate,
    this.accountId,
    this.color = 0xFF4CAF50,
    this.icon = 0xe57f,
  });
}

/// Datos para actualizar una meta de ahorro.
class UpdateSavingsGoalData {
  final String? name;
  final String? description;
  final double? targetAmount;
  final DateTime? targetDate;
  final String? accountId;
  final int? color;
  final int? icon;

  const UpdateSavingsGoalData({
    this.name,
    this.description,
    this.targetAmount,
    this.targetDate,
    this.accountId,
    this.color,
    this.icon,
  });
}

/// Resumen agregado de metas de ahorro.
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

/// Interface de repositorio para metas de ahorro.
abstract class SavingsGoalRepository {
  /// Obtiene todas las metas activas.
  Future<List<SavingsGoalData>> getActiveGoals();

  /// Obtiene todas las metas completadas.
  Future<List<SavingsGoalData>> getCompletedGoals();

  /// Obtiene metas en progreso (activas y no completadas).
  Future<List<SavingsGoalData>> getGoalsInProgress();

  /// Obtiene una meta por ID.
  Future<SavingsGoalData?> getGoalById(String id);

  /// Inserta una nueva meta.
  Future<void> insertGoal(String id, CreateSavingsGoalData data);

  /// Actualiza una meta existente.
  Future<void> updateGoal(String id, UpdateSavingsGoalData data);

  /// Elimina una meta y sus contribuciones.
  Future<void> deleteGoal(String id);

  /// Activa una meta pausada.
  Future<void> activateGoal(String id);

  /// Pausa una meta activa.
  Future<void> pauseGoal(String id);

  /// Stream de metas activas.
  Stream<List<SavingsGoalData>> watchActiveGoals();

  /// Stream de metas en progreso.
  Stream<List<SavingsGoalData>> watchGoalsInProgress();
}

/// Interface de repositorio para contribuciones.
abstract class SavingsContributionRepository {
  /// Obtiene contribuciones de una meta.
  Future<List<SavingsContributionData>> getContributionsForGoal(String goalId);

  /// Agrega una contribución a una meta.
  /// Retorna el ID de la contribución creada.
  Future<String> addContribution({
    required String id,
    required String goalId,
    required double amount,
    String? note,
    required DateTime date,
  });

  /// Elimina una contribución.
  Future<void> deleteContribution(String contributionId);

  /// Stream de contribuciones de una meta.
  Stream<List<SavingsContributionData>> watchContributionsForGoal(String goalId);
}
