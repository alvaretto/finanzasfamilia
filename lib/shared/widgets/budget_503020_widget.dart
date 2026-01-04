import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../utils/budget_50_30_20.dart';

/// Widget que muestra el análisis de presupuesto según la regla 50/30/20
class Budget503020Widget extends StatelessWidget {
  final Budget503020 budget;

  const Budget503020Widget({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

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
                  '📊 Regla 50/30/20',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: '50% Necesidades, 30% Gustos, 20% Ahorros',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Ingresos del mes
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tus ingresos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    currencyFormatter.format(budget.monthlyIncome),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 50% Necesidades
            _buildCategoryRow(
              context: context,
              emoji: '🏠',
              title: 'Necesidades (50%)',
              subtitle: 'Vivienda, comida, servicios',
              target: budget.necessitiesTarget,
              actual: budget.necessitiesSpent,
              percentage: budget.necessitiesPercentage,
              status: budget.necessitiesStatus,
              currencyFormatter: currencyFormatter,
              color: AppColors.expense,
            ),
            const SizedBox(height: AppSpacing.md),

            // 30% Gustos
            _buildCategoryRow(
              context: context,
              emoji: '🎮',
              title: 'Gustos (30%)',
              subtitle: 'Entretenimiento, salidas',
              target: budget.wantsTarget,
              actual: budget.wantsSpent,
              percentage: budget.wantsPercentage,
              status: budget.wantsStatus,
              currencyFormatter: currencyFormatter,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),

            // 20% Ahorros
            _buildCategoryRow(
              context: context,
              emoji: '💰',
              title: 'Ahorros (20%)',
              subtitle: 'Inversiones, fondo emergencia',
              target: budget.savingsTarget,
              actual: budget.savings,
              percentage: budget.savingsPercentage,
              status: budget.savingsStatus,
              currencyFormatter: currencyFormatter,
              color: AppColors.income,
            ),
            const SizedBox(height: AppSpacing.md),

            // Mensaje general
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _getMessageColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: _getMessageColor(context).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                budget.overallMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getMessageColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // Recomendaciones
            if (budget.recommendations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Recomendaciones:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...budget.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            rec,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required double target,
    required double actual,
    required double percentage,
    required BudgetStatus status,
    required NumberFormat currencyFormatter,
    required Color color,
  }) {
    // Calcular progreso (0.0 a 1.0+)
    final progress = target > 0 ? (actual / target).clamp(0.0, 1.5) : 0.0;
    final isOverBudget = actual > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${status.emoji} ${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status, color),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverBudget ? AppColors.error : color,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Montos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gastaste: ${currencyFormatter.format(actual)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            Text(
              'Meta: ${currencyFormatter.format(target)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(BudgetStatus status, Color defaultColor) {
    switch (status) {
      case BudgetStatus.good:
        return defaultColor;
      case BudgetStatus.high:
        return AppColors.error;
      case BudgetStatus.low:
        return AppColors.warning;
    }
  }

  Color _getMessageColor(BuildContext context) {
    final totalSpent = budget.necessitiesSpent + budget.wantsSpent;
    final totalBudget = budget.necessitiesTarget + budget.wantsTarget;

    if (totalSpent <= totalBudget && budget.savings >= budget.savingsTarget) {
      return AppColors.income;
    } else if (totalSpent > totalBudget) {
      return AppColors.error;
    }
    return AppColors.warning;
  }
}
