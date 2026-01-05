import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../services/ant_expense_service.dart';
import '../utils/ant_expense_analysis.dart';

/// Widget que muestra el análisis de gastos hormiga
class AntExpenseWidget extends StatelessWidget {
  final AntExpenseAnalysis analysis;

  const AntExpenseWidget({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    // No mostrar si no hay gastos hormiga significativos
    if (analysis.impact == AntExpenseImpact.none) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con emoji e icono de ayuda
            Row(
              children: [
                Text(
                  analysis.impactMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getImpactColor(analysis.impact),
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message:
                      'Pequeñas compras (< \$${AntExpenseService.antExpenseThreshold.toStringAsFixed(0)}) que sumadas pueden representar mucho dinero',
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Total y cantidad de transacciones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _getImpactColor(analysis.impact).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _getImpactColor(analysis.impact).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pequeñas compras que suman:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${analysis.totalAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getImpactColor(analysis.impact),
                            ),
                      ),
                      Text(
                        '${analysis.totalTransactions} compras',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Top 3 categorías
            if (analysis.topCategories.isNotEmpty) ...[
              Text(
                'Las más frecuentes:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...analysis.topCategories.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        // Barra de impacto
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryImpactColor(cat.impact),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Datos de categoría
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${cat.total.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${cat.frequency} veces • \$${cat.average.toStringAsFixed(0)} promedio',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Ahorro potencial
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.income.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.income,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Si reduces estos gastos, podrías ahorrar \$${analysis.potentialSavings.toStringAsFixed(0)} al mes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.income,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getImpactColor(AntExpenseImpact impact) {
    switch (impact) {
      case AntExpenseImpact.high:
        return AppColors.error;
      case AntExpenseImpact.medium:
        return AppColors.warning;
      case AntExpenseImpact.low:
        return AppColors.secondary;
      case AntExpenseImpact.none:
        return AppColors.income;
    }
  }

  Color _getCategoryImpactColor(CategoryImpact impact) {
    switch (impact) {
      case CategoryImpact.high:
        return AppColors.error;
      case CategoryImpact.medium:
        return AppColors.warning;
      case CategoryImpact.low:
        return AppColors.secondary;
    }
  }
}
