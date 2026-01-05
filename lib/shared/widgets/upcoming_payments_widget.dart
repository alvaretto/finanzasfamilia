import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../utils/upcoming_payments.dart';

/// Widget que muestra próximos pagos con urgencia
class UpcomingPaymentsWidget extends StatelessWidget {
  final List<UpcomingPayment> payments;

  const UpcomingPaymentsWidget({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    // No mostrar si no hay pagos próximos
    if (payments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Mostrar máximo 5 pagos más urgentes
    final displayPayments = payments.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Text(
                  '📅 Próximos Pagos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Badge con cantidad de pagos urgentes
                if (UpcomingPaymentsService.hasUrgentPayments(payments))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _getUrgentCount(payments).toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Lista de pagos
            ...displayPayments.map((payment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildPaymentItem(context, payment),
                )),

            // Mostrar total si hay más de 5
            if (payments.length > 5) ...[
              const Divider(),
              Text(
                '${payments.length - 5} pagos más próximos...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, UpcomingPayment payment) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _getUrgencyColor(payment.urgency).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: _getUrgencyColor(payment.urgency).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Emoji de urgencia
          Text(
            payment.urgencyEmoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Información del pago
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción
                Text(
                  payment.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Fecha y urgencia
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: _getUrgencyColor(payment.urgency),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(payment.dueDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getUrgencyColor(payment.urgency),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '• ${payment.urgencyMessage}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getUrgencyColor(payment.urgency),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Monto
          Text(
            '\$${payment.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getUrgencyColor(payment.urgency),
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Hoy';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Mañana';
    } else {
      return DateFormat('d MMM', 'es').format(date);
    }
  }

  Color _getUrgencyColor(PaymentUrgency urgency) {
    switch (urgency) {
      case PaymentUrgency.overdue:
      case PaymentUrgency.urgent:
        return AppColors.error;
      case PaymentUrgency.soon:
        return AppColors.warning;
      case PaymentUrgency.upcoming:
        return AppColors.secondary;
    }
  }

  int _getUrgentCount(List<UpcomingPayment> payments) {
    return payments.where((p) =>
      p.urgency == PaymentUrgency.overdue ||
      p.urgency == PaymentUrgency.urgent
    ).length;
  }
}
