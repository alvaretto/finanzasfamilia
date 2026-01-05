import '../../features/budgets/domain/models/budget_model.dart';

/// Nivel de urgencia de un pago próximo
enum PaymentUrgency {
  overdue, // Ya pasó la fecha
  urgent, // 1-3 días
  soon, // 4-7 días
  upcoming, // 8-15 días
}

/// Pago próximo con nivel de urgencia
class UpcomingPayment {
  final String id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String? categoryName;
  final PaymentType type;

  const UpcomingPayment({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.categoryName,
    required this.type,
  });

  /// Calcular urgencia basado en la fecha
  PaymentUrgency get urgency {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) return PaymentUrgency.overdue;
    if (difference <= 3) return PaymentUrgency.urgent;
    if (difference <= 7) return PaymentUrgency.soon;
    return PaymentUrgency.upcoming;
  }

  /// Días restantes (negativo si ya pasó)
  int get daysRemaining {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }

  /// Mensaje de urgencia
  String get urgencyMessage {
    switch (urgency) {
      case PaymentUrgency.overdue:
        final days = daysRemaining.abs();
        return days == 0 ? 'Hoy era el pago' : 'Vencido hace $days días';
      case PaymentUrgency.urgent:
        return daysRemaining == 0
            ? '¡Hoy vence!'
            : daysRemaining == 1
                ? 'Mañana vence'
                : 'En $daysRemaining días';
      case PaymentUrgency.soon:
        return 'En $daysRemaining días';
      case PaymentUrgency.upcoming:
        return 'En $daysRemaining días';
    }
  }

  /// Emoji según urgencia
  String get urgencyEmoji {
    switch (urgency) {
      case PaymentUrgency.overdue:
        return '🔴';
      case PaymentUrgency.urgent:
        return '⚠️';
      case PaymentUrgency.soon:
        return '🟡';
      case PaymentUrgency.upcoming:
        return '🟢';
    }
  }

  /// Crear desde presupuesto recurrente
  static UpcomingPayment fromBudget(BudgetModel budget) {
    // Calcular próxima fecha de vencimiento según el período
    final now = DateTime.now();
    DateTime dueDate;

    switch (budget.period) {
      case BudgetPeriod.monthly:
        // Último día del mes actual
        dueDate = DateTime(now.year, now.month + 1, 0);
        break;
      case BudgetPeriod.weekly:
        // Próximo domingo
        final daysUntilSunday = 7 - now.weekday;
        dueDate = now.add(Duration(days: daysUntilSunday));
        break;
      case BudgetPeriod.yearly:
        // Fin de año
        dueDate = DateTime(now.year, 12, 31);
        break;
    }

    return UpcomingPayment(
      id: budget.id,
      description: 'Presupuesto ${budget.categoryName ?? "sin categoría"}',
      amount: budget.amount,
      dueDate: dueDate,
      categoryName: budget.categoryName,
      type: PaymentType.budget,
    );
  }
}

/// Tipo de pago
enum PaymentType {
  budget, // Presupuesto recurrente
  bill, // Factura/servicio
  subscription, // Suscripción
  loan, // Préstamo/deuda
  other, // Otro
}

/// Servicio para gestionar pagos próximos
class UpcomingPaymentsService {
  /// Obtener pagos próximos de presupuestos
  static List<UpcomingPayment> getUpcomingFromBudgets(
    List<BudgetModel> budgets,
  ) {
    final now = DateTime.now();
    final payments = <UpcomingPayment>[];

    for (final budget in budgets) {
      // Solo incluir presupuestos activos
      if (budget.endDate != null && budget.endDate!.isBefore(now)) {
        continue;
      }

      final payment = UpcomingPayment.fromBudget(budget);

      // Solo incluir si faltan menos de 15 días
      if (payment.daysRemaining <= 15) {
        payments.add(payment);
      }
    }

    // Ordenar por urgencia (más urgente primero)
    payments.sort((a, b) {
      // Primero por urgencia
      final urgencyOrder = {
        PaymentUrgency.overdue: 0,
        PaymentUrgency.urgent: 1,
        PaymentUrgency.soon: 2,
        PaymentUrgency.upcoming: 3,
      };

      final urgencyCompare =
          urgencyOrder[a.urgency]!.compareTo(urgencyOrder[b.urgency]!);
      if (urgencyCompare != 0) return urgencyCompare;

      // Luego por días restantes
      return a.daysRemaining.compareTo(b.daysRemaining);
    });

    return payments;
  }

  /// Verificar si hay pagos urgentes
  static bool hasUrgentPayments(List<UpcomingPayment> payments) {
    return payments.any(
      (p) => p.urgency == PaymentUrgency.urgent || p.urgency == PaymentUrgency.overdue,
    );
  }

  /// Contar pagos por urgencia
  static Map<PaymentUrgency, int> countByUrgency(
    List<UpcomingPayment> payments,
  ) {
    final counts = <PaymentUrgency, int>{
      PaymentUrgency.overdue: 0,
      PaymentUrgency.urgent: 0,
      PaymentUrgency.soon: 0,
      PaymentUrgency.upcoming: 0,
    };

    for (final payment in payments) {
      counts[payment.urgency] = (counts[payment.urgency] ?? 0) + 1;
    }

    return counts;
  }
}
