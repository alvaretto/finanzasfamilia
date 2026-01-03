import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_budget_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          if (state.isSyncing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetSheet(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.budgets.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => ref.read(budgetsProvider.notifier).syncBudgets(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _buildMonthlySummary(context, state, currencyFormat),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.overBudgets.isNotEmpty) ...[
                        _buildWarningBanner(context, state.overBudgets.length),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      ...state.budgets.map((budget) => _BudgetCard(
                            budget: budget,
                            currencyFormat: currencyFormat,
                            onTap: () => _showEditBudgetSheet(context, budget),
                            onDelete: () => _confirmDelete(context, ref, budget),
                          )),
                      const SizedBox(height: AppSpacing.xl),
                    ],
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
            Icons.pie_chart_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sin presupuestos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Crea un presupuesto para controlar\ntus gastos por categoría',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showAddBudgetSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear presupuesto'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(
    BuildContext context,
    BudgetsState state,
    NumberFormat format,
  ) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'es').format(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              monthName[0].toUpperCase() + monthName.substring(1),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Presupuestado',
                  value: format.format(state.totalBudgeted),
                  color: AppColors.primary,
                ),
                _SummaryItem(
                  label: 'Gastado',
                  value: format.format(state.totalSpent),
                  color: AppColors.expense,
                ),
                _SummaryItem(
                  label: 'Disponible',
                  value: format.format(state.totalBudgeted - state.totalSpent),
                  color: AppColors.income,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              count == 1
                  ? 'Tienes 1 presupuesto excedido'
                  : 'Tienes $count presupuestos excedidos',
              style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddBudgetSheet(),
    );
  }

  void _showEditBudgetSheet(BuildContext context, BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddBudgetSheet(budget: budget),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetModel budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: Text(
          '¿Eliminar el presupuesto de "${budget.categoryName ?? 'Sin categoría'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(budgetsProvider.notifier).deleteBudget(budget.id);
    }
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.currencyFormat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = budget.percentSpent / 100;
    final color = _parseColor(budget.categoryColor) ?? AppColors.primary;

    Color progressColor;
    if (budget.isOverBudget) {
      progressColor = AppColors.expense;
    } else if (budget.isNearLimit) {
      progressColor = AppColors.warning;
    } else {
      progressColor = color;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      _getIconData(budget.categoryIcon),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.categoryName ?? 'Sin categoría',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${currencyFormat.format(budget.spent)} de ${currencyFormat.format(budget.amount)}',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${budget.percentSpent.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                      ),
                      if (budget.isOverBudget)
                        Row(
                          children: [
                            const Icon(Icons.warning, size: 14, color: AppColors.expense),
                            const SizedBox(width: 4),
                            const Text(
                              'Excedido',
                              style: TextStyle(fontSize: 10, color: AppColors.expense),
                            ),
                          ],
                        ),
                      Text(
                        budget.period.shortName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0, 1),
                  backgroundColor: progressColor.withValues(alpha: 0.1),
                  color: progressColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
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

  IconData _getIconData(String? iconName) {
    const icons = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'power': Icons.power,
      'favorite': Icons.favorite,
      'movie': Icons.movie,
      'shopping_bag': Icons.shopping_bag,
      'school': Icons.school,
      'more_horiz': Icons.more_horiz,
    };
    return icons[iconName] ?? Icons.category;
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
