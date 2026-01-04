import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'goal_model.freezed.dart';
part 'goal_model.g.dart';

const _uuid = Uuid();

/// Modelo de meta de ahorro
@freezed
class GoalModel with _$GoalModel {
  const GoalModel._();

  const factory GoalModel({
    required String id,
    required String userId,
    String? familyId,
    required String name,
    required double targetAmount,
    @Default(0.0) double currentAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
    @Default(false) bool isSynced,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _GoalModel;

  factory GoalModel.fromJson(Map<String, dynamic> json) =>
      _$GoalModelFromJson(json);

  /// Crear nueva meta
  factory GoalModel.create({
    required String userId,
    required String name,
    required double targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
    String? familyId,
  }) {
    return GoalModel(
      id: _uuid.v4(),
      userId: userId,
      familyId: familyId,
      name: name,
      targetAmount: targetAmount.abs(),
      currentAmount: currentAmount?.abs() ?? 0,
      targetDate: targetDate,
      icon: icon ?? 'savings',
      color: color ?? '#6366F1',
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  /// Porcentaje completado
  double get percentComplete =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  /// Monto restante
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  /// Está completada
  bool get isCompleted => currentAmount >= targetAmount;

  /// Días restantes
  int? get daysRemaining {
    if (targetDate == null) return null;
    final diff = targetDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Ahorro mensual necesario para cumplir la meta
  double? get monthlyNeeded {
    if (targetDate == null || isCompleted) return null;
    final months = targetDate!.difference(DateTime.now()).inDays / 30;
    if (months <= 0) return remaining;
    return remaining / months;
  }

  /// Convierte a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'family_id': familyId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'icon': icon,
      'color': color,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Crear desde respuesta de Supabase
  factory GoalModel.fromSupabase(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      familyId: json['family_id'] as String?,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isSynced: true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
