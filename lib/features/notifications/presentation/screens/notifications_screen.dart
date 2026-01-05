import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/notification_item.dart';
import '../../../../shared/services/notification_aggregator_service.dart';
import '../../../../shared/services/financial_health_service.dart';
import '../../../../shared/services/ant_expense_service.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsProvider);
    final accountsState = ref.watch(accountsProvider);
    final budgetsState = ref.watch(budgetsProvider);
    final goalsState = ref.watch(goalsProvider);

    // Obtener datos
    final transactions = transactionsState.transactions;
    final accounts = accountsState.accounts;
    final budgets = budgetsState.budgets;
    final goals = goalsState.activeGoals;

    // Calcular análisis
    final financialHealth = FinancialHealthService.calculate(
      accounts: accounts,
      transactions: transactions,
      monthlyIncome: transactionsState.totalIncome,
      monthlyExpenses: transactionsState.totalExpenses,
    );

    final antExpenseAnalysis =
        AntExpenseService.analyzeCurrentMonth(transactions);

    // Generar notificaciones
    final notifications = NotificationAggregatorService.generateNotifications(
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      accounts: accounts,
      financialHealth: financialHealth,
      antExpenseAnalysis: antExpenseAnalysis,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // TODO: Marcar todas como leídas
              },
              child: const Text('Marcar todas como leídas'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '¡Todo al día!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No tienes notificaciones pendientes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationItem notification,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: _getBackgroundColor(notification.priority, notification.isRead),
      child: InkWell(
        onTap: () {
          if (notification.actionRoute != null) {
            context.push(notification.actionRoute!);
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji
                  Text(
                    notification.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getTextColor(notification.priority),
                                    ),
                              ),
                            ),
                            // Badge de prioridad
                            if (notification.priority == NotificationPriority.high)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  'URGENTE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Mensaje
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Timestamp
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Indicador de no leído
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notification.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              // Botón de acción
              if (notification.actionLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (notification.actionRoute != null) {
                        context.push(notification.actionRoute!);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getTextColor(notification.priority),
                      side: BorderSide(
                        color: _getTextColor(notification.priority)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(notification.actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Justo ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('d MMM', 'es').format(timestamp);
    }
  }

  Color _getBackgroundColor(NotificationPriority priority, bool isRead) {
    if (isRead) {
      return Colors.grey.withValues(alpha: 0.05);
    }

    switch (priority) {
      case NotificationPriority.high:
        return AppColors.error.withValues(alpha: 0.1);
      case NotificationPriority.medium:
        return AppColors.warning.withValues(alpha: 0.1);
      case NotificationPriority.low:
        return AppColors.info.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return AppColors.error;
      case NotificationPriority.medium:
        return AppColors.warning;
      case NotificationPriority.low:
        return AppColors.info;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return AppColors.error;
      case NotificationPriority.medium:
        return AppColors.warning;
      case NotificationPriority.low:
        return AppColors.secondary;
    }
  }
}
