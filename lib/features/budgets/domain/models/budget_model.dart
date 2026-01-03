import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_model.freezed.dart';
part 'budget_model.g.dart';

/// Periodo del presupuesto
enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Semanal';
      case BudgetPeriod.monthly:
        return 'Mensual';
      case BudgetPeriod.yearly:
        return 'Anual';
    }
  }

  String get shortName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'sem';
      case BudgetPeriod.monthly:
        return 'mes';
      case BudgetPeriod.yearly:
        return 'año';
    }
  }
}

/// Modelo de presupuesto
@freezed
class BudgetModel with _$BudgetModel {
  const BudgetModel._();

  const factory BudgetModel({
    required String id,
    required String userId,
    String? familyId,
    required int categoryId,
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
    @Default(false) bool isSynced,
    DateTime? createdAt,
    // Campos para UI (no persistidos)
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    @Default(0.0) double spent,
  }) = _BudgetModel;

  factory BudgetModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetModelFromJson(json);

  /// Crear nuevo presupuesto
  factory BudgetModel.create({
    required String userId,
    required int categoryId,
    required double amount,
    required BudgetPeriod period,
    DateTime? startDate,
    DateTime? endDate,
    String? familyId,
  }) {
    final now = DateTime.now();
    DateTime start = startDate ?? DateTime(now.year, now.month, 1);

    return BudgetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      familyId: familyId,
      categoryId: categoryId,
      amount: amount.abs(),
      period: period,
      startDate: start,
      endDate: endDate,
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  /// Porcentaje gastado
  double get percentSpent => amount > 0 ? (spent / amount * 100).clamp(0, 200) : 0;

  /// Disponible
  double get remaining => amount - spent;

  /// Está excedido
  bool get isOverBudget => spent > amount;

  /// Está cerca del límite (>80%)
  bool get isNearLimit => percentSpent >= 80 && percentSpent < 100;

  /// Convierte a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'family_id': familyId,
      'category_id': categoryId,
      'amount': amount,
      'period': period.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  /// Crear desde respuesta de Supabase
  factory BudgetModel.fromSupabase(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      familyId: json['family_id'] as String?,
      categoryId: json['category_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isSynced: true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
