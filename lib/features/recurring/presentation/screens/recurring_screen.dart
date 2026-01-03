import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/recurring_model.dart';
import '../providers/recurring_provider.dart';
import '../widgets/add_recurring_sheet.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    // Escuchar mensajes
    ref.listen<RecurringState>(recurringProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(recurringProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(recurringProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(recurringProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => ref.read(recurringProvider.notifier).refresh(),
                  child: CustomScrollView(
                    slivers: [
                      // Resumen
                      SliverToBoxAdapter(
                        child: _buildSummary(context, state, currencyFormat),
                      ),

                      // Pendientes
                      if (state.pending.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: AppColors.warning, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Pendientes (${state.pending.length})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = state.pending[index];
                              return _RecurringTile(
                                recurring: item,
                                isPending: true,
                                currencyFormat: currencyFormat,
                              );
                            },
                            childCount: state.pending.length,
                          ),
                        ),
                      ],

                      // Todas
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: Text(
                            'Todas (${state.items.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = state.items[index];
                            return _RecurringTile(
                              recurring: item,
                              currencyFormat: currencyFormat,
                            );
                          },
                          childCount: state.items.length,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sin transacciones recurrentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Agrega pagos o ingresos que se\nrepiten automáticamente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    RecurringState state,
    NumberFormat format,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimado mensual',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_upward,
                                color: AppColors.income, size: 16),
                            const SizedBox(width: 4),
                            Text('Ingresos',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        Text(
                          format.format(state.monthlyIncome),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.income,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_downward,
                                color: AppColors.expense, size: 16),
                            const SizedBox(width: 4),
                            Text('Gastos',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        Text(
                          format.format(state.monthlyExpense),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.balance,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text('Balance',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        Text(
                          format.format(
                              state.monthlyIncome - state.monthlyExpense),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: state.monthlyIncome >=
                                            state.monthlyExpense
                                        ? AppColors.income
                                        : AppColors.expense,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddRecurringSheet(),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  final RecurringModel recurring;
  final bool isPending;
  final NumberFormat currencyFormat;

  const _RecurringTile({
    required this.recurring,
    this.isPending = false,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM', 'es');
    final isIncome = recurring.type == RecurringType.income;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () => _showOptions(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icono
              CircleAvatar(
                backgroundColor: (isIncome ? AppColors.income : AppColors.expense)
                    .withValues(alpha: 0.1),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? AppColors.income : AppColors.expense,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recurring.description ?? recurring.categoryName ?? 'Sin descripción',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!recurring.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Pausado',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recurring.frequency.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isPending ? AppColors.warning : Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(recurring.nextOccurrence),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isPending ? AppColors.warning : Theme.of(context).colorScheme.outline,
                                fontWeight: isPending ? FontWeight.w600 : null,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Monto
              Text(
                '${isIncome ? '+' : '-'}${currencyFormat.format(recurring.amount)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            if (recurring.isActive && (recurring.isDueToday || recurring.isOverdue)) ...[
              ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.success),
                title: const Text('Registrar transacción'),
                subtitle: const Text('Crear transacción real'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(recurringProvider.notifier).execute(recurring);
                },
              ),
              ListTile(
                leading: Icon(Icons.skip_next, color: AppColors.warning),
                title: const Text('Omitir esta vez'),
                subtitle: const Text('Saltar a la siguiente ocurrencia'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(recurringProvider.notifier).skip(recurring);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: Icon(
                recurring.isActive ? Icons.pause : Icons.play_arrow,
                color: AppColors.info,
              ),
              title: Text(recurring.isActive ? 'Pausar' : 'Reanudar'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(recurringProvider.notifier)
                    .toggleActive(recurring.id, !recurring.isActive);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddRecurringSheet(recurring: recurring),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('Eliminar', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar'),
                    content: const Text(
                      '¿Eliminar esta transacción recurrente?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(recurringProvider.notifier).delete(recurring.id);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
