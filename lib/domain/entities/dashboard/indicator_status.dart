/// Estado de un indicador financiero
enum IndicatorStatus {
  good,
  warning,
  danger,
}

/// Calcula el estado del indicador basado en porcentaje de presupuesto
IndicatorStatus calculateIndicatorStatus(double percentage) {
  if (percentage >= 100) return IndicatorStatus.danger;
  if (percentage >= 80) return IndicatorStatus.warning;
  return IndicatorStatus.good;
}
