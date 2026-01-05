/// Sistema de evaluación de salud financiera personal
///
/// Calcula métricas clave y una puntuación global (0-100) basada en:
/// - Capacidad de ahorro (40 puntos)
/// - Nivel de endeudamiento (30 puntos)
/// - Liquidez / Fondo de emergencia (30 puntos)
class FinancialHealth {
  final double monthlyIncome;
  final double monthlyExpenses;
  final double totalAssets;
  final double totalLiabilities;
  final double fixedExpenses;
  final double emergencyFund;

  FinancialHealth({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.fixedExpenses,
    required this.emergencyFund,
  });

  // ==================== INDICADOR 1: CAPACIDAD DE AHORRO ====================

  /// Tasa de ahorro mensual (%)
  double get savingsRate {
    if (monthlyIncome == 0) return 0;
    final savings = monthlyIncome - monthlyExpenses;
    return (savings / monthlyIncome) * 100;
  }

  /// Mensaje sobre la tasa de ahorro
  String get savingsRateMessage {
    if (savingsRate >= 20) {
      return '🎉 Excelente ahorro';
    } else if (savingsRate >= 10) {
      return '👍 Buen ahorro';
    } else if (savingsRate > 0) {
      return '⚠️ Ahorro bajo';
    } else {
      return '🔴 Sin ahorro';
    }
  }

  /// Puntos por capacidad de ahorro (máximo 40)
  int get savingsPoints {
    if (savingsRate >= 20) return 40;
    if (savingsRate >= 15) return 30;
    if (savingsRate >= 10) return 20;
    if (savingsRate >= 5) return 10;
    return 0;
  }

  // ==================== INDICADOR 2: NIVEL DE ENDEUDAMIENTO ====================

  /// Nivel de endeudamiento (% deudas sobre activos)
  double get debtLevel {
    if (totalAssets == 0) return 0;
    return (totalLiabilities / totalAssets) * 100;
  }

  /// Mensaje sobre el nivel de deuda
  String get debtLevelMessage {
    if (debtLevel < 30) {
      return '✅ Deuda saludable';
    } else if (debtLevel < 50) {
      return '⚠️ Deuda moderada';
    } else {
      return '🔴 Nivel de deuda alto';
    }
  }

  /// Puntos por nivel de endeudamiento (máximo 30)
  int get debtPoints {
    if (debtLevel < 30) return 30;
    if (debtLevel < 50) return 20;
    if (debtLevel < 70) return 10;
    return 0;
  }

  // ==================== INDICADOR 3: LIQUIDEZ ====================

  /// Meses de cobertura del fondo de emergencia
  int get emergencyCoverageMonths {
    if (fixedExpenses == 0) return 0;
    return (emergencyFund / fixedExpenses).floor();
  }

  /// Mensaje sobre liquidez
  String get liquidityMessage {
    if (emergencyCoverageMonths >= 6) {
      return '✅ Fondo de emergencia sólido';
    } else if (emergencyCoverageMonths >= 3) {
      return '👍 Fondo aceptable';
    } else if (emergencyCoverageMonths >= 1) {
      return '⚠️ Fondo insuficiente';
    } else {
      return '🔴 Sin fondo de emergencia';
    }
  }

  /// Puntos por liquidez (máximo 30)
  int get liquidityPoints {
    if (emergencyCoverageMonths >= 6) return 30;
    if (emergencyCoverageMonths >= 3) return 20;
    if (emergencyCoverageMonths >= 1) return 10;
    return 0;
  }

  // ==================== PUNTUACIÓN GLOBAL ====================

  /// Puntuación global de salud financiera (0-100)
  int get globalScore {
    return savingsPoints + debtPoints + liquidityPoints;
  }

  /// Nivel de salud financiera según puntuación
  HealthLevel get healthLevel {
    if (globalScore >= 80) return HealthLevel.excellent;
    if (globalScore >= 60) return HealthLevel.good;
    if (globalScore >= 40) return HealthLevel.fair;
    return HealthLevel.needsAttention;
  }

  /// Mensaje del nivel de salud
  String get healthLevelMessage {
    switch (healthLevel) {
      case HealthLevel.excellent:
        return '🎉 Excelente';
      case HealthLevel.good:
        return '👍 Buena';
      case HealthLevel.fair:
        return '⚠️ Regular';
      case HealthLevel.needsAttention:
        return '🔴 Necesita atención';
    }
  }

  // ==================== RECOMENDACIONES ====================

  /// Recomendaciones personalizadas
  List<String> get recommendations {
    final recs = <String>[];

    // Recomendación 1: Ahorro
    if (savingsRate < 20) {
      final needed = 20 - savingsRate;
      recs.add(
        'Aumenta tu ahorro en ${needed.toStringAsFixed(1)}% para llegar al 20% recomendado',
      );
    }

    // Recomendación 2: Deuda
    if (debtLevel >= 50) {
      recs.add('Prioriza reducir tus deudas. Tu nivel está en ${debtLevel.toStringAsFixed(0)}%');
    } else if (debtLevel >= 30) {
      recs.add('Mantén controladas tus deudas y evita endeudarte más');
    }

    // Recomendación 3: Fondo de emergencia
    if (emergencyCoverageMonths < 6) {
      final monthsNeeded = 6 - emergencyCoverageMonths;
      final amountNeeded = fixedExpenses * monthsNeeded;
      recs.add(
        'Completa tu fondo de emergencia. Te faltan $monthsNeeded meses (\$${amountNeeded.toStringAsFixed(0)})',
      );
    }

    // Si todo está bien
    if (recs.isEmpty) {
      recs.add('¡Excelente! Sigues buenas prácticas financieras. Mantén este ritmo');
    }

    return recs;
  }

  // ==================== DETALLES COMPLETOS ====================

  /// Mapa con todos los detalles de la evaluación
  Map<String, dynamic> toDetailsMap() {
    return {
      'savings': {
        'rate': savingsRate,
        'message': savingsRateMessage,
        'points': savingsPoints,
        'maxPoints': 40,
        'target': 20.0, // 20% recomendado
      },
      'debt': {
        'level': debtLevel,
        'message': debtLevelMessage,
        'points': debtPoints,
        'maxPoints': 30,
        'target': 30.0, // <30% recomendado
      },
      'liquidity': {
        'months': emergencyCoverageMonths,
        'message': liquidityMessage,
        'points': liquidityPoints,
        'maxPoints': 30,
        'target': 6, // 6 meses recomendado
      },
      'global': {
        'score': globalScore,
        'maxScore': 100,
        'level': healthLevel.name,
        'message': healthLevelMessage,
      },
      'recommendations': recommendations,
    };
  }
}

/// Niveles de salud financiera
enum HealthLevel {
  excellent,      // 80-100 puntos
  good,          // 60-79 puntos
  fair,          // 40-59 puntos
  needsAttention, // 0-39 puntos
}

extension HealthLevelExtension on HealthLevel {
  String get displayName {
    switch (this) {
      case HealthLevel.excellent:
        return 'Excelente';
      case HealthLevel.good:
        return 'Buena';
      case HealthLevel.fair:
        return 'Regular';
      case HealthLevel.needsAttention:
        return 'Necesita Atención';
    }
  }

  String get emoji {
    switch (this) {
      case HealthLevel.excellent:
        return '🎉';
      case HealthLevel.good:
        return '👍';
      case HealthLevel.fair:
        return '⚠️';
      case HealthLevel.needsAttention:
        return '🔴';
    }
  }
}
