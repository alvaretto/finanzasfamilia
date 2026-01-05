/// Tipo de notificación
enum NotificationType {
  budgetExceeded, // Presupuesto excedido
  budgetWarning, // Cerca del límite
  largeExpense, // Gasto grande
  lowBalance, // Saldo bajo
  paymentDue, // Pago próximo
  goalNearCompletion, // Meta casi cumplida
  antExpenses, // Gastos hormiga detectados
  tip, // Consejo de Fina
  achievement, // Logro financiero
}

/// Prioridad de la notificación
enum NotificationPriority {
  high, // Rojo - requiere atención inmediata
  medium, // Amarillo - importante pero no urgente
  low, // Verde - informativo
}

/// Item de notificación
class NotificationItem {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.actionLabel,
    this.metadata,
  });

  /// Emoji según tipo
  String get emoji {
    switch (type) {
      case NotificationType.budgetExceeded:
        return '⚠️';
      case NotificationType.budgetWarning:
        return '📊';
      case NotificationType.largeExpense:
        return '💸';
      case NotificationType.lowBalance:
        return '🔔';
      case NotificationType.paymentDue:
        return '📅';
      case NotificationType.goalNearCompletion:
        return '🎯';
      case NotificationType.antExpenses:
        return '🐜';
      case NotificationType.tip:
        return '💡';
      case NotificationType.achievement:
        return '🎉';
    }
  }

  /// Copiar con campos modificados
  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
    );
  }
}
