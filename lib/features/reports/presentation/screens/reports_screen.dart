import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/report_model.dart';
import '../providers/report_provider.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/line_chart_widget.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(reportProvider.notifier).loadReport(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.summary == null
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => ref.read(reportProvider.notifier).loadReport(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector de periodo
                        _PeriodSelector(
                          selected: state.selectedPeriod,
                          onChanged: (period) =>
                              ref.read(reportProvider.notifier).setPeriod(period),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Resumen
                        _buildSummaryCards(context, state.summary!, currencyFormat),
                        const SizedBox(height: AppSpacing.lg),

                        // Gráfico de flujo mensual
                        _buildFlowChart(context, state.summary!),
                        const SizedBox(height: AppSpacing.lg),

                        // Gráfico de gastos por categoría
                        _buildCategoryChart(context, state.summary!, currencyFormat),
                        const SizedBox(height: AppSpacing.lg),

                        // Gráfico de tendencia
                        _buildTrendChart(context, state.summary!),
                        const SizedBox(height: AppSpacing.lg),

                        // Top categorías
                        _buildTopCategories(context, state.summary!, currencyFormat),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sin datos para mostrar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Registra transacciones para ver\ntus reportes aquí',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    ReportSummary summary,
    NumberFormat format,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Ingresos',
            value: format.format(summary.totalIncome),
            change: summary.previousIncome > 0
                ? '${summary.incomeChange >= 0 ? '+' : ''}${summary.incomeChange.toStringAsFixed(0)}%'
                : null,
            isPositive: summary.isIncomeChangePositive,
            icon: Icons.arrow_upward,
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            title: 'Gastos',
            value: format.format(summary.totalExpense),
            change: summary.previousExpense > 0
                ? '${summary.expenseChange >= 0 ? '+' : ''}${summary.expenseChange.toStringAsFixed(0)}%'
                : null,
            isPositive: summary.isExpenseChangePositive,
            icon: Icons.arrow_downward,
            color: AppColors.expense,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowChart(BuildContext context, ReportSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Flujo de Efectivo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FlowBarChart(data: summary.monthlyFlow),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(
    BuildContext context,
    ReportSummary summary,
    NumberFormat format,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Distribución de Gastos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExpensePieChart(
              categories: summary.topExpenseCategories,
              totalExpense: summary.totalExpense,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, ReportSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Tendencia de Gastos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TrendLineChart(data: summary.dailyTrend),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    ReportSummary summary,
    NumberFormat format,
  ) {
    if (summary.topExpenseCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Top Categorías de Gasto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...summary.topExpenseCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              final color = _parseColor(cat.color) ??
                  AppColors.categoryColors[index % AppColors.categoryColors.length];

              return _CategoryItem(
                name: cat.name,
                amount: cat.amount,
                percentage: cat.percentage,
                color: color,
                format: format,
              );
            }),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportPeriod.values
            .where((p) => p != ReportPeriod.custom)
            .map((period) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _PeriodChip(
                    label: period.displayName,
                    isSelected: selected == period,
                    onTap: () => onChanged(period),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (change != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  change!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final NumberFormat format;

  const _CategoryItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(name)),
              Text(
                format.format(amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 45,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
