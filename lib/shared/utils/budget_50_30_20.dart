/// Calculadora de presupuesto según la regla 50/30/20
///
/// - 50% Necesidades: Vivienda, alimentación, transporte, servicios, deudas
/// - 30% Gustos: Entretenimiento, salidas, hobbies, compras no esenciales
/// - 20% Ahorros: Inversiones, fondo de emergencia, pago extra de deudas
class Budget503020 {
  final double monthlyIncome;
  final double necessitiesSpent;
  final double wantsSpent;
  final double savings;

  Budget503020({
    required this.monthlyIncome,
    required this.necessitiesSpent,
    required this.wantsSpent,
    required this.savings,
  });

  // Presupuestos recomendados según la regla 50/30/20
  double get necessitiesTarget => monthlyIncome * 0.50;
  double get wantsTarget => monthlyIncome * 0.30;
  double get savingsTarget => monthlyIncome * 0.20;

  // Porcentajes actuales
  double get necessitiesPercentage =>
    monthlyIncome > 0 ? (necessitiesSpent / monthlyIncome) * 100 : 0;

  double get wantsPercentage =>
    monthlyIncome > 0 ? (wantsSpent / monthlyIncome) * 100 : 0;

  double get savingsPercentage =>
    monthlyIncome > 0 ? (savings / monthlyIncome) * 100 : 0;

  // Diferencias (positivo = te sobra, negativo = te pasaste)
  double get necessitiesDifference => necessitiesTarget - necessitiesSpent;
  double get wantsDifference => wantsTarget - wantsSpent;
  double get savingsDifference => savings - savingsTarget;

  // Estados (bien, alto, bajo)
  BudgetStatus get necessitiesStatus {
    if (necessitiesSpent <= necessitiesTarget) {
      return BudgetStatus.good;
    }
    return BudgetStatus.high;
  }

  BudgetStatus get wantsStatus {
    if (wantsSpent <= wantsTarget) {
      return BudgetStatus.good;
    }
    return BudgetStatus.high;
  }

  BudgetStatus get savingsStatus {
    if (savings >= savingsTarget) {
      return BudgetStatus.good;
    }
    return BudgetStatus.low;
  }

  /// Mensaje motivacional general
  String get overallMessage {
    final totalSpent = necessitiesSpent + wantsSpent;
    final totalBudget = necessitiesTarget + wantsTarget;

    if (totalSpent <= totalBudget && savings >= savingsTarget) {
      return '¡Excelente! Cumples la regla 50/30/20';
    } else if (totalSpent > totalBudget) {
      final excess = totalSpent - totalBudget;
      return 'Te excediste \$${excess.toStringAsFixed(0)} en gastos';
    } else if (savings < savingsTarget) {
      final needed = savingsTarget - savings;
      return 'Te faltan \$${needed.toStringAsFixed(0)} para tu meta de ahorro';
    }

    return 'Vas por buen camino';
  }

  /// Recomendaciones específicas
  List<String> get recommendations {
    final recs = <String>[];

    if (necessitiesStatus == BudgetStatus.high) {
      recs.add('Reduce gastos en necesidades (vivienda, servicios, transporte)');
    }

    if (wantsStatus == BudgetStatus.high) {
      recs.add('Modera gastos en entretenimiento y compras no esenciales');
    }

    if (savingsStatus == BudgetStatus.low) {
      final needed = savingsTarget - savings;
      recs.add('Intenta ahorrar \$${needed.toStringAsFixed(0)} más este mes');
    }

    if (recs.isEmpty) {
      recs.add('¡Sigue así! Estás manejando bien tus finanzas');
    }

    return recs;
  }

  /// Validación completa del presupuesto
  Map<String, dynamic> toValidationMap() {
    return {
      'necessities': {
        'target': necessitiesTarget,
        'actual': necessitiesSpent,
        'difference': necessitiesDifference,
        'percentage': necessitiesPercentage,
        'status': necessitiesStatus.name,
      },
      'wants': {
        'target': wantsTarget,
        'actual': wantsSpent,
        'difference': wantsDifference,
        'percentage': wantsPercentage,
        'status': wantsStatus.name,
      },
      'savings': {
        'target': savingsTarget,
        'actual': savings,
        'difference': savingsDifference,
        'percentage': savingsPercentage,
        'status': savingsStatus.name,
      },
    };
  }
}

enum BudgetStatus {
  good,   // Dentro del presupuesto
  high,   // Te excediste
  low,    // Por debajo del objetivo (solo para ahorros)
}

extension BudgetStatusExtension on BudgetStatus {
  String get displayName {
    switch (this) {
      case BudgetStatus.good:
        return 'Bien';
      case BudgetStatus.high:
        return 'Alto';
      case BudgetStatus.low:
        return 'Bajo';
    }
  }

  String get emoji {
    switch (this) {
      case BudgetStatus.good:
        return '✅';
      case BudgetStatus.high:
        return '⚠️';
      case BudgetStatus.low:
        return '📉';
    }
  }
}
