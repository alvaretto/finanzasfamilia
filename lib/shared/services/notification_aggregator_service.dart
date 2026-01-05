import '../../features/accounts/domain/models/account_model.dart';
import '../../features/budgets/domain/models/budget_model.dart';
import '../../features/goals/domain/models/goal_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../models/notification_item.dart';
import '../utils/upcoming_payments.dart';
import '../utils/ant_expense_analysis.dart';
import '../utils/financial_health.dart';
import 'contextual_tips_service.dart';

/// Servicio que agrega todas las notificaciones del sistema
class NotificationAggregatorService {
  /// Generar todas las notificaciones relevantes
  static List<NotificationItem> generateNotifications({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<GoalModel> goals,
    required List<AccountModel> accounts,
    FinancialHealth? financialHealth,
    AntExpenseAnalysis? antExpenseAnalysis,
  }) {
    final notifications = <NotificationItem>[];
    final now = DateTime.now();

    // 1. Alertas de presupuestos excedidos
    final exceededBudgets = budgets.where((b) => b.isOverBudget).toList();
    for (final budget in exceededBudgets) {
      final excess = budget.spent - budget.amount;
      notifications.add(NotificationItem(
        id: 'budget_exceeded_${budget.id}',
        type: NotificationType.budgetExceeded,
        priority: NotificationPriority.high,
        title: 'Presupuesto Excedido',
        message:
            'Te pasaste por \$${excess.toStringAsFixed(0)} en ${budget.categoryName ?? "esta categoría"}',
        timestamp: now,
        actionRoute: '/budgets',
        actionLabel: 'Ver presupuestos',
        metadata: {'budgetId': budget.id, 'categoryId': budget.categoryId},
      ));
    }

    // 2. Alertas de presupuestos cerca del límite
    final nearLimitBudgets =
        budgets.where((b) => b.isNearLimit && !b.isOverBudget).toList();
    for (final budget in nearLimitBudgets) {
      notifications.add(NotificationItem(
        id: 'budget_warning_${budget.id}',
        type: NotificationType.budgetWarning,
        priority: NotificationPriority.medium,
        title: 'Cerca del Límite',
        message:
            'Vas en ${budget.percentSpent.toStringAsFixed(0)}% de tu presupuesto en ${budget.categoryName ?? "esta categoría"}',
        timestamp: now,
        actionRoute: '/budgets',
        actionLabel: 'Ver detalles',
        metadata: {'budgetId': budget.id, 'categoryId': budget.categoryId},
      ));
    }

    // 3. Gastos grandes recientes (últimos 3 días)
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final largeExpenses = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.amount > 500000 &&
            t.date.isAfter(threeDaysAgo))
        .toList();

    for (final tx in largeExpenses.take(3)) {
      // Máximo 3
      notifications.add(NotificationItem(
        id: 'large_expense_${tx.id}',
        type: NotificationType.largeExpense,
        priority: NotificationPriority.medium,
        title: 'Gasto Grande Detectado',
        message:
            'Gastaste \$${tx.amount.toStringAsFixed(0)} en ${tx.categoryName ?? "esta compra"}',
        timestamp: tx.date,
        actionRoute: '/transactions',
        actionLabel: 'Ver movimientos',
        metadata: {'transactionId': tx.id},
      ));
    }

    // 4. Saldos bajos
    final lowBalanceAccounts = accounts
        .where((a) =>
            (a.type == AccountType.bank || a.type == AccountType.savings) &&
            a.balance < 100000 &&
            a.balance >= 0)
        .toList();

    for (final account in lowBalanceAccounts) {
      notifications.add(NotificationItem(
        id: 'low_balance_${account.id}',
        type: NotificationType.lowBalance,
        priority: NotificationPriority.high,
        title: 'Saldo Bajo',
        message: '${account.name}: \$${account.balance.toStringAsFixed(0)}',
        timestamp: now,
        actionRoute: '/accounts',
        actionLabel: 'Ver cuentas',
        metadata: {'accountId': account.id},
      ));
    }

    // 5. Pagos próximos urgentes
    final upcomingPayments = UpcomingPaymentsService.getUpcomingFromBudgets(budgets);
    final urgentPayments = upcomingPayments
        .where((p) =>
            p.urgency == PaymentUrgency.urgent ||
            p.urgency == PaymentUrgency.overdue)
        .toList();

    for (final payment in urgentPayments) {
      notifications.add(NotificationItem(
        id: 'payment_due_${payment.id}',
        type: NotificationType.paymentDue,
        priority: payment.urgency == PaymentUrgency.overdue
            ? NotificationPriority.high
            : NotificationPriority.medium,
        title: payment.urgency == PaymentUrgency.overdue
            ? 'Pago Vencido'
            : 'Pago Próximo',
        message: '${payment.description} - ${payment.urgencyMessage}',
        timestamp: now,
        actionRoute: '/budgets',
        actionLabel: 'Ver detalles',
        metadata: {'paymentId': payment.id, 'dueDate': payment.dueDate.toIso8601String()},
      ));
    }

    // 6. Metas próximas a completarse
    final nearGoals =
        goals.where((g) => !g.isCompleted && g.percentComplete >= 80).toList();

    for (final goal in nearGoals) {
      final remaining = goal.targetAmount - goal.currentAmount;
      notifications.add(NotificationItem(
        id: 'goal_near_${goal.id}',
        type: NotificationType.goalNearCompletion,
        priority: NotificationPriority.low,
        title: '¡Casi Llegas a tu Meta!',
        message: 'Solo te faltan \$${remaining.toStringAsFixed(0)} para ${goal.name}',
        timestamp: now,
        actionRoute: '/goals',
        actionLabel: 'Ver metas',
        metadata: {'goalId': goal.id},
      ));
    }

    // 7. Gastos hormiga significativos
    if (antExpenseAnalysis != null &&
        antExpenseAnalysis.impact == AntExpenseImpact.high) {
      final topCategory = antExpenseAnalysis.topCategories.isNotEmpty
          ? antExpenseAnalysis.topCategories.first.name
          : 'gastos pequeños';

      notifications.add(NotificationItem(
        id: 'ant_expenses_${now.month}',
        type: NotificationType.antExpenses,
        priority: NotificationPriority.medium,
        title: 'Gastos Hormiga Detectados',
        message:
            'Llevas \$${antExpenseAnalysis.totalAmount.toStringAsFixed(0)} en $topCategory este mes',
        timestamp: now,
        actionLabel: 'Ver análisis',
        metadata: {
          'totalAmount': antExpenseAnalysis.totalAmount,
          'topCategory': topCategory,
        },
      ));
    }

    // 8. Consejo importante de Fina (si aplica)
    final tip = ContextualTipsService.getContextualTip(
      recentTransactions: transactions,
      budgets: budgets,
      goals: goals,
      financialHealth: financialHealth,
      antExpenseAnalysis: antExpenseAnalysis,
    );

    if (tip != null &&
        (tip.context == TipContext.budgetExceeded ||
            tip.context == TipContext.lowFinancialHealth ||
            tip.context == TipContext.antExpenses)) {
      notifications.add(NotificationItem(
        id: 'tip_${tip.context.name}',
        type: NotificationType.tip,
        priority: NotificationPriority.low,
        title: tip.title,
        message: tip.message,
        timestamp: now,
        actionRoute: tip.actionRoute,
        actionLabel: tip.actionText,
      ));
    }

    // 9. Logros (salud financiera excelente)
    if (financialHealth != null &&
        financialHealth.healthLevel == HealthLevel.excellent) {
      notifications.add(NotificationItem(
        id: 'achievement_excellent_health',
        type: NotificationType.achievement,
        priority: NotificationPriority.low,
        title: '¡Excelente Salud Financiera!',
        message: 'Tus finanzas están muy bien. ¡Sigue así!',
        timestamp: now,
        actionLabel: 'Ver detalles',
        metadata: {'score': financialHealth.globalScore},
      ));
    }

    // Ordenar por prioridad y timestamp
    notifications.sort((a, b) {
      // Primero por prioridad
      final priorityOrder = {
        NotificationPriority.high: 0,
        NotificationPriority.medium: 1,
        NotificationPriority.low: 2,
      };

      final priorityCompare =
          priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (priorityCompare != 0) return priorityCompare;

      // Luego por timestamp (más reciente primero)
      return b.timestamp.compareTo(a.timestamp);
    });

    return notifications;
  }

  /// Contar notificaciones no leídas
  static int countUnread(List<NotificationItem> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }

  /// Contar notificaciones por prioridad
  static Map<NotificationPriority, int> countByPriority(
    List<NotificationItem> notifications,
  ) {
    final counts = <NotificationPriority, int>{
      NotificationPriority.high: 0,
      NotificationPriority.medium: 0,
      NotificationPriority.low: 0,
    };

    for (final notification in notifications) {
      counts[notification.priority] = (counts[notification.priority] ?? 0) + 1;
    }

    return counts;
  }

  /// Verificar si hay notificaciones de alta prioridad
  static bool hasHighPriority(List<NotificationItem> notifications) {
    return notifications.any((n) => n.priority == NotificationPriority.high);
  }
}
