import 'package:freezed_annotation/freezed_annotation.dart';

part 'savings_goal.freezed.dart';
part 'savings_goal.g.dart';

/// Estado de la meta de ahorro
enum SavingsGoalStatus {
  /// En progreso - Meta activa, no completada
  inProgress,

  /// Completada - Meta alcanzada
  completed,

  /// Vencida - Fecha límite pasada sin completar
  overdue,

  /// Pausada - Meta desactivada temporalmente
  paused,
}

/// Entidad de Meta de Ahorro inmutable
/// Representa un objetivo financiero con monto y fecha límite
@freezed
class SavingsGoal with _$SavingsGoal {
  const SavingsGoal._();

  const factory SavingsGoal({
    required String id,
    required String name,
    String? description,
    required double targetAmount,
    @Default(0.0) double currentAmount,
    DateTime? targetDate,
    String? accountId,
    @Default(0xFF4CAF50) int color,
    @Default(0xe57f) int icon, // savings icon
    @Default(true) bool isActive,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SavingsGoal;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) =>
      _$SavingsGoalFromJson(json);

  /// Porcentaje de progreso (0-100+)
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  /// Porcentaje de progreso limitado a 100
  double get progressPercentageCapped {
    final percentage = progressPercentage;
    return percentage > 100 ? 100 : percentage;
  }

  /// Monto restante para alcanzar la meta
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica si la meta fue alcanzada
  bool get hasReachedTarget => currentAmount >= targetAmount;

  /// Días restantes hasta la fecha límite
  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    if (targetDate!.isBefore(now)) return 0;
    return targetDate!.difference(now).inDays;
  }

  /// Verifica si está vencida
  bool get isOverdue {
    if (targetDate == null || isCompleted) return false;
    return targetDate!.isBefore(DateTime.now());
  }

  /// Estado actual de la meta
  SavingsGoalStatus get status {
    if (!isActive) return SavingsGoalStatus.paused;
    if (isCompleted) return SavingsGoalStatus.completed;
    if (isOverdue) return SavingsGoalStatus.overdue;
    return SavingsGoalStatus.inProgress;
  }

  /// Ahorro diario necesario para alcanzar la meta a tiempo
  double? get dailySavingsNeeded {
    if (targetDate == null || hasReachedTarget) return null;
    final days = daysRemaining;
    if (days == null || days <= 0) return null;
    return remainingAmount / days;
  }

  /// Ahorro mensual necesario para alcanzar la meta a tiempo
  double? get monthlySavingsNeeded {
    final daily = dailySavingsNeeded;
    if (daily == null) return null;
    return daily * 30;
  }

  /// Nombre del estado en español
  String get statusName {
    switch (status) {
      case SavingsGoalStatus.inProgress:
        return 'En progreso';
      case SavingsGoalStatus.completed:
        return 'Completada';
      case SavingsGoalStatus.overdue:
        return 'Vencida';
      case SavingsGoalStatus.paused:
        return 'Pausada';
    }
  }

  /// Formato de fecha límite
  String? get formattedTargetDate {
    if (targetDate == null) return null;
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${targetDate!.day} ${months[targetDate!.month]} ${targetDate!.year}';
  }
}

/// Entidad de Contribución a Meta de Ahorro
@freezed
class SavingsContribution with _$SavingsContribution {
  const SavingsContribution._();

  const factory SavingsContribution({
    required String id,
    required String goalId,
    required double amount,
    String? note,
    required DateTime date,
    required DateTime createdAt,
  }) = _SavingsContribution;

  factory SavingsContribution.fromJson(Map<String, dynamic> json) =>
      _$SavingsContributionFromJson(json);
}
