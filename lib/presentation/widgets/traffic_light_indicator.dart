import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Estado del semáforo de presupuesto para UI
enum TrafficLightStatus {
  /// Verde: < 80% del presupuesto
  safe,

  /// Amarillo: 80-99% del presupuesto
  warning,

  /// Rojo: >= 100% del presupuesto
  exceeded,
}

/// Datos para mostrar en el indicador de semáforo
class TrafficLightData {
  final double spent;
  final double budgetAmount;
  final double percentage;
  final TrafficLightStatus status;

  const TrafficLightData({
    required this.spent,
    required this.budgetAmount,
    required this.percentage,
    required this.status,
  });

  double get remaining => budgetAmount - spent;

  /// Factory para crear desde porcentaje
  factory TrafficLightData.fromPercentage({
    required double spent,
    required double budgetAmount,
  }) {
    final percentage = budgetAmount > 0 ? (spent / budgetAmount) * 100 : 0.0;
    final status = _calculateStatus(percentage);
    return TrafficLightData(
      spent: spent,
      budgetAmount: budgetAmount,
      percentage: percentage,
      status: status,
    );
  }

  static TrafficLightStatus _calculateStatus(double percentage) {
    if (percentage >= 100) {
      return TrafficLightStatus.exceeded;
    } else if (percentage >= 80) {
      return TrafficLightStatus.warning;
    } else {
      return TrafficLightStatus.safe;
    }
  }
}

/// Widget de semáforo para indicar el estado del presupuesto
///
/// Colores:
/// - Verde (safe): < 80% del presupuesto usado
/// - Amarillo (warning): 80-99% del presupuesto usado
/// - Rojo (exceeded): >= 100% del presupuesto usado
class TrafficLightIndicator extends StatelessWidget {
  final TrafficLightData data;
  final bool showAmounts;
  final bool compact;

  const TrafficLightIndicator({
    super.key,
    required this.data,
    this.showAmounts = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    if (compact) {
      return _buildCompact(color);
    }

    return _buildFull(context, color);
  }

  /// Construye el indicador compacto (solo círculo de color)
  Widget _buildCompact(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  /// Construye el indicador completo con porcentaje y montos
  Widget _buildFull(BuildContext context, Color color) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicador circular con porcentaje
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Text(
              '${data.percentage.toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        // Montos si están habilitados
        if (showAmounts) ...[
          const SizedBox(height: 8),
          Text(
            '${currencyFormat.format(data.spent)} / ${currencyFormat.format(data.budgetAmount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Restante: ${currencyFormat.format(data.remaining)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: data.remaining >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  /// Obtiene el color basado en el estado del presupuesto
  Color _getColor() {
    switch (data.status) {
      case TrafficLightStatus.safe:
        return Colors.green;
      case TrafficLightStatus.warning:
        return Colors.amber;
      case TrafficLightStatus.exceeded:
        return Colors.red;
    }
  }
}
