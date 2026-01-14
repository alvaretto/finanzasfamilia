import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// Estado del presupuesto basado en semáforo
enum BudgetStatus {
  /// Verde - Menos del 80% gastado
  safe,

  /// Amarillo - Entre 80% y 99% gastado
  warning,

  /// Rojo - 100% o más gastado
  exceeded,
}

/// Entidad de Presupuesto inmutable
/// Representa un límite de gasto mensual por categoría
@freezed
class Budget with _$Budget {
  const Budget._();

  const factory Budget({
    required String id,
    required String categoryId,
    required double amount,
    required int month,
    required int year,
    String? notes,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  /// Calcula el porcentaje gastado
  double percentageUsed(double spent) {
    if (amount <= 0) return 0;
    return (spent / amount) * 100;
  }

  /// Determina el estado del semáforo
  BudgetStatus status(double spent) {
    final percentage = percentageUsed(spent);
    if (percentage >= 100) return BudgetStatus.exceeded;
    if (percentage >= 80) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  /// Verifica si está excedido
  bool isExceeded(double spent) => spent >= amount;

  /// Verifica si está en advertencia (80-99%)
  bool isWarning(double spent) {
    final percentage = percentageUsed(spent);
    return percentage >= 80 && percentage < 100;
  }

  /// Calcula el monto disponible
  double available(double spent) => amount - spent;

  /// Nombre del período (ej: "Enero 2026")
  String get periodName {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${months[month]} $year';
  }
}
