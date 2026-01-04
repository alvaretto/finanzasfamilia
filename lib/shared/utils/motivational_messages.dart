/// Generador de mensajes motivacionales basados en el estado financiero
class MotivationalMessages {
  /// Genera un mensaje motivacional basado en la tasa de ahorro
  static String forSavingsRate(double savingsRate) {
    if (savingsRate >= 30) {
      return '¡Excelente! Estás ahorrando ${savingsRate.toStringAsFixed(1)}% de tus ingresos. Eres un campeón del ahorro';
    } else if (savingsRate >= 20) {
      return '¡Muy bien! Estás ahorrando ${savingsRate.toStringAsFixed(1)}%. Vas por buen camino';
    } else if (savingsRate >= 10) {
      return 'Buen trabajo. Ahorraste ${savingsRate.toStringAsFixed(1)}%. Intenta llegar al 20%';
    } else if (savingsRate > 0) {
      return 'Estás ahorrando ${savingsRate.toStringAsFixed(1)}%. Poco a poco llegarás a tu meta';
    } else if (savingsRate == 0) {
      return 'Este mes no ahorraste. ¿Qué tal si empiezas con un pequeño monto?';
    } else {
      return 'Gastaste más de lo que recibiste. Revisa tus gastos y ajusta tu presupuesto';
    }
  }

  /// Genera un mensaje basado en el balance del periodo
  static String forPeriodBalance(double balance, double income) {
    if (income == 0) {
      return 'No hay movimientos este mes. ¡Registra tus transacciones para ver tu progreso!';
    }

    if (balance > 0) {
      return '¡Te sobró dinero este mes! Considera guardarlo en una meta de ahorro';
    } else if (balance == 0) {
      return 'Gastaste exactamente lo que ganaste. Intenta ahorrar un poco el próximo mes';
    } else {
      final deficit = balance.abs();
      return 'Te faltaron \$${deficit.toStringAsFixed(0)}. Revisa tus gastos y ajusta para el próximo mes';
    }
  }

  /// Mensaje según el patrimonio neto
  static String forNetWorth(double netWorth, double? previousNetWorth) {
    if (previousNetWorth == null) {
      if (netWorth > 0) {
        return 'Tu patrimonio neto es positivo. ¡Buen comienzo!';
      } else if (netWorth == 0) {
        return 'Empieza a construir tu patrimonio ahorrando cada mes';
      } else {
        return 'Tienes más deudas que ahorros. Trabaja en reducir tus deudas';
      }
    }

    final change = netWorth - previousNetWorth;
    final percentChange = previousNetWorth != 0
        ? (change / previousNetWorth.abs()) * 100
        : 0.0;

    if (change > 0) {
      return '¡Tu patrimonio creció \$${change.toStringAsFixed(0)}! (${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%)';
    } else if (change == 0) {
      return 'Tu patrimonio se mantuvo estable este mes';
    } else {
      return 'Tu patrimonio disminuyó \$${change.abs().toStringAsFixed(0)}. Revisa tus gastos';
    }
  }

  /// Mensaje según presupuesto usado
  static String forBudgetUsage(double used, double planned) {
    if (planned == 0) {
      return 'Define presupuestos para controlar mejor tus gastos';
    }

    final percentage = (used / planned) * 100;

    if (percentage < 70) {
      return '¡Excelente control! Solo usaste el ${percentage.toStringAsFixed(0)}% del presupuesto';
    } else if (percentage < 90) {
      return 'Buen ritmo. Usaste el ${percentage.toStringAsFixed(0)}% del presupuesto';
    } else if (percentage < 100) {
      return '⚠️ Cuidado. Ya usaste el ${percentage.toStringAsFixed(0)}% del presupuesto';
    } else {
      final excess = used - planned;
      return '⚠️ Te excediste \$${excess.toStringAsFixed(0)} del presupuesto';
    }
  }

  /// Mensaje de racha de ahorro
  static String forSavingStreak(int consecutiveMonthsSaving) {
    if (consecutiveMonthsSaving == 0) {
      return 'Empieza tu racha de ahorro este mes';
    } else if (consecutiveMonthsSaving == 1) {
      return '¡Primer mes ahorrando! Sigue así';
    } else if (consecutiveMonthsSaving < 3) {
      return '¡$consecutiveMonthsSaving meses ahorrando! Mantén el impulso';
    } else if (consecutiveMonthsSaving < 6) {
      return '¡$consecutiveMonthsSaving meses consecutivos ahorrando! Estás formando un gran hábito';
    } else {
      return '¡Increíble! $consecutiveMonthsSaving meses ahorrando sin parar. Eres un ejemplo a seguir';
    }
  }

  /// Mensaje general de progreso
  static String forGeneralProgress({
    required double savingsRate,
    required double netWorth,
    required bool hasEmergencyFund,
    required int activeGoals,
  }) {
    // Caso excepcional: muy buen desempeño
    if (savingsRate >= 20 && netWorth > 0 && hasEmergencyFund) {
      return '¡Vas excelente! Sigues buenas prácticas financieras. Sigue así';
    }

    // Caso positivo: buen ahorro
    if (savingsRate >= 15) {
      return '¡Buen trabajo! Tu disciplina de ahorro está dando frutos';
    }

    // Caso: tiene metas activas
    if (activeGoals > 0) {
      return 'Tienes $activeGoals ${activeGoals == 1 ? 'meta activa' : 'metas activas'}. ¡Sigue trabajando en ${activeGoals == 1 ? 'ella' : 'ellas'}!';
    }

    // Caso: patrimonio positivo
    if (netWorth > 0) {
      return 'Tu patrimonio es positivo. Define metas para seguir creciendo';
    }

    // Caso predeterminado: motivación general
    return 'Cada paso cuenta. Registra tus gastos y define metas para mejorar tus finanzas';
  }

  /// Tip del día (rotativo)
  static String getTipOfTheDay(DateTime date) {
    final dayOfMonth = date.day;
    final tips = [
      'Tip: Ahorra al menos el 20% de tus ingresos cada mes',
      'Tip: Usa la regla 50/30/20: Necesidades, Gustos, Ahorros',
      'Tip: Crea un fondo de emergencia de 6 meses de gastos',
      'Tip: Revisa tus suscripciones. ¿Realmente usas todas?',
      'Tip: Cocina en casa más seguido para ahorrar en restaurantes',
      'Tip: Define metas específicas para tu ahorro',
      'Tip: Evita compras impulsivas. Espera 24 horas antes de comprar',
      'Tip: Compara precios antes de comprar artículos grandes',
      'Tip: Paga tus deudas de mayor interés primero',
      'Tip: Automatiza tu ahorro para que sea más fácil',
      'Tip: Revisa tu presupuesto semanalmente',
      'Tip: Busca formas de aumentar tus ingresos',
      'Tip: Invierte en tu educación financiera',
      'Tip: Negocia tus servicios (internet, celular, seguros)',
      'Tip: Lleva la cuenta de gastos pequeños. Se acumulan',
      'Tip: Planifica tus compras del mes con anticipación',
      'Tip: Usa cupones y descuentos sin comprometer calidad',
      'Tip: Revisa tu progreso mensual y ajusta tu plan',
      'Tip: Celebra tus logros financieros, por pequeños que sean',
      'Tip: Comparte tus metas con alguien de confianza',
      'Tip: Evita usar tarjetas de crédito para gastos diarios',
      'Tip: Aprende la diferencia entre querer y necesitar',
      'Tip: Vende lo que no uses para generar ingresos extra',
      'Tip: Establece límites de gasto para categorías específicas',
      'Tip: Revisa tus estados de cuenta bancarios regularmente',
      'Tip: Prioriza experiencias sobre posesiones materiales',
      'Tip: Crea un presupuesto realista que puedas mantener',
      'Tip: Edúcate sobre inversiones y haz crecer tu dinero',
      'Tip: Ten cuidado con los "gastos hormiga" diarios',
      'Tip: Planifica para gastos irregulares (regalos, vacaciones)',
    ];

    return tips[dayOfMonth % tips.length];
  }
}
