import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../utils/financial_health.dart';

/// Widget que muestra los indicadores de salud financiera
class FinancialHealthWidget extends StatelessWidget {
  final FinancialHealth health;

  const FinancialHealthWidget({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
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
                  '🏥 Tu Salud Financiera',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: 'Evaluación automática basada en ahorro, deuda y liquidez',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Puntuación global
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradientColors(health.healthLevel),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    'Puntuación',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${health.globalScore}/100',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    health.healthLevelMessage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Detalles de indicadores
            Text(
              'Detalles:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 1. Capacidad de ahorro
            _buildIndicatorRow(
              context: context,
              icon: '💰',
              title: 'Capacidad de Ahorro',
              value: '${health.savingsRate.toStringAsFixed(1)}%',
              message: health.savingsRateMessage,
              points: health.savingsPoints,
              maxPoints: 40,
              target: '20%',
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Nivel de deuda
            _buildIndicatorRow(
              context: context,
              icon: '💳',
              title: 'Nivel de Deuda',
              value: '${health.debtLevel.toStringAsFixed(1)}%',
              message: health.debtLevelMessage,
              points: health.debtPoints,
              maxPoints: 30,
              target: '<30%',
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Fondo de emergencia
            _buildIndicatorRow(
              context: context,
              icon: '🏦',
              title: 'Fondo de Emergencia',
              value: '${health.emergencyCoverageMonths} meses',
              message: health.liquidityMessage,
              points: health.liquidityPoints,
              maxPoints: 30,
              target: '6 meses',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recomendaciones
            if (health.recommendations.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Recomendaciones:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...health.recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                            left: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow({
    required BuildContext context,
    required String icon,
    required String title,
    required String value,
    required String message,
    required int points,
    required int maxPoints,
    required String target,
  }) {
    final progress = maxPoints > 0 ? points / maxPoints : 0.0;

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
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _getMessageColor(message),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Valor y target
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actual: $value',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            Text(
              'Objetivo: $target',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Barra de progreso de puntos
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progress),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$points/$maxPoints pts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  List<Color> _getGradientColors(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return [AppColors.income, AppColors.income.withValues(alpha: 0.8)];
      case HealthLevel.good:
        return [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)];
      case HealthLevel.fair:
        return [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)];
      case HealthLevel.needsAttention:
        return [AppColors.error, AppColors.error.withValues(alpha: 0.8)];
    }
  }

  Color _getMessageColor(String message) {
    if (message.contains('✅') || message.contains('🎉')) {
      return AppColors.income;
    } else if (message.contains('👍')) {
      return AppColors.secondary;
    } else if (message.contains('⚠️')) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.income;
    if (progress >= 0.5) return AppColors.secondary;
    if (progress >= 0.3) return AppColors.warning;
    return AppColors.error;
  }
}
