import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../utils/month_comparison.dart';

/// Widget que muestra la comparación visual entre dos meses
class MonthComparisonWidget extends StatelessWidget {
  final MonthComparison comparison;

  const MonthComparisonWidget({
    super.key,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    // No mostrar si es el primer mes (sin datos previos)
    if (comparison.previousTransactionCount == 0) {
      return const SizedBox.shrink();
    }

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
                  '📊 Comparación Mensual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: 'Cómo va este mes comparado con el anterior',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${comparison.currentMonthName} vs ${comparison.previousMonthName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Resumen con emoji
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _getSummaryColor(comparison.balanceImproved)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _getSummaryColor(comparison.balanceImproved)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    comparison.performanceEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      comparison.summaryMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getSummaryColor(comparison.balanceImproved),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Detalles de comparación
            _buildComparisonRow(
              context: context,
              icon: Icons.arrow_upward,
              iconColor: AppColors.income,
              label: 'Ingresos',
              current: comparison.currentIncome,
              previous: comparison.previousIncome,
              message: comparison.incomeMessage,
              isPositive: comparison.incomeImproved,
            ),
            const SizedBox(height: AppSpacing.md),

            _buildComparisonRow(
              context: context,
              icon: Icons.arrow_downward,
              iconColor: AppColors.expense,
              label: 'Gastos',
              current: comparison.currentExpenses,
              previous: comparison.previousExpenses,
              message: comparison.expensesMessage,
              isPositive: comparison.expensesReduced,
            ),
            const SizedBox(height: AppSpacing.md),

            _buildComparisonRow(
              context: context,
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.secondary,
              label: 'Balance',
              current: comparison.currentBalance,
              previous: comparison.previousBalance,
              message: comparison.balanceMessage,
              isPositive: comparison.balanceImproved,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required double current,
    required double previous,
    required String message,
    required bool isPositive,
  }) {
    return Row(
      children: [
        // Icono
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Datos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Valor actual
                  Text(
                    '\$${current.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  // Cambio porcentual
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.income : AppColors.error)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPositive ? AppColors.income : AppColors.error,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Mes anterior: \$${previous.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSummaryColor(bool improved) {
    return improved ? AppColors.income : AppColors.warning;
  }
}
