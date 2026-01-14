import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/providers.dart';
import '../widgets/traffic_light_indicator.dart';

/// Provider para el mes/año seleccionado en presupuestos
final budgetPeriodProvider = StateProvider<({int month, int year})>((ref) {
  final now = DateTime.now();
  return (month: now.month, year: now.year);
});

/// Provider de presupuestos del período seleccionado (usando servicio de dominio)
final periodBudgetsProvider = FutureProvider<List<BudgetData>>((ref) async {
  final service = ref.watch(budgetServiceProvider);
  final period = ref.watch(budgetPeriodProvider);
  return service.getBudgetsForMonth(period.month, period.year);
});

/// Provider de gastos por categoría en el período
final periodExpensesProvider = FutureProvider<Map<String, double>>((ref) async {
  final dao = ref.watch(transactionsDaoProvider);
  final period = ref.watch(budgetPeriodProvider);

  final startDate = DateTime(period.year, period.month, 1);
  final endDate = DateTime(period.year, period.month + 1, 0, 23, 59, 59);

  final transactions = await dao.getTransactionsInPeriod(startDate, endDate);

  final expenseMap = <String, double>{};
  for (final tx in transactions.where((t) => t.type == 'expense')) {
    expenseMap[tx.categoryId] = (expenseMap[tx.categoryId] ?? 0) + tx.amount;
  }
  return expenseMap;
});

/// Pantalla de gestión de presupuestos
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(budgetPeriodProvider);
    final budgetsAsync = ref.watch(periodBudgetsProvider);
    final expensesAsync = ref.watch(periodExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(periodBudgetsProvider);
              ref.invalidate(periodExpensesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de período
          _PeriodSelector(
            month: period.month,
            year: period.year,
            onPeriodChanged: (month, year) {
              ref.read(budgetPeriodProvider.notifier).state = (month: month, year: year);
            },
          ),

          // Resumen del período
          expensesAsync.when(
            data: (expenses) => budgetsAsync.when(
              data: (budgets) => _BudgetSummary(
                budgets: budgets,
                expenses: expenses,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Lista de presupuestos
          Expanded(
            child: budgetsAsync.when(
              data: (budgets) => expensesAsync.when(
                data: (expenses) => _BudgetsList(
                  budgets: budgets,
                  expenses: expenses,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(periodBudgetsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddBudgetDialog(),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int month, int year) onPeriodChanged;

  const _PeriodSelector({
    required this.month,
    required this.year,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              if (month == 1) {
                onPeriodChanged(12, year - 1);
              } else {
                onPeriodChanged(month - 1, year);
              }
            },
          ),
          const SizedBox(width: 16),
          Text(
            '${monthNames[month]} $year',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              if (month == 12) {
                onPeriodChanged(1, year + 1);
              } else {
                onPeriodChanged(month + 1, year);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  final List<BudgetData> budgets;
  final Map<String, double> expenses;

  const _BudgetSummary({
    required this.budgets,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) return const SizedBox.shrink();

    double totalBudget = 0;
    double totalSpent = 0;

    for (final budget in budgets) {
      totalBudget += budget.amount;
      totalSpent += expenses[budget.categoryId] ?? 0;
    }

    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
    final remaining = totalBudget - totalSpent;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    TrafficLightStatus status;
    if (percentage >= 100) {
      status = TrafficLightStatus.exceeded;
    } else if (percentage >= 80) {
      status = TrafficLightStatus.warning;
    } else {
      status = TrafficLightStatus.safe;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                TrafficLightIndicator(
                  data: TrafficLightData(
                    spent: totalSpent,
                    budgetAmount: totalBudget,
                    percentage: percentage,
                    status: status,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen del mes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(totalSpent)} de ${currencyFormat.format(totalBudget)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                    Text(
                      remaining >= 0
                          ? 'Disponible: ${currencyFormat.format(remaining)}'
                          : 'Excedido: ${currencyFormat.format(remaining.abs())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: remaining >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_getStatusColor(status)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TrafficLightStatus status) {
    switch (status) {
      case TrafficLightStatus.safe:
        return Colors.green;
      case TrafficLightStatus.warning:
        return Colors.orange;
      case TrafficLightStatus.exceeded:
        return Colors.red;
    }
  }
}

class _BudgetsList extends ConsumerWidget {
  final List<BudgetData> budgets;
  final Map<String, double> expenses;

  const _BudgetsList({
    required this.budgets,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay presupuestos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca + para crear uno',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final spent = expenses[budget.categoryId] ?? 0;
        return _BudgetCard(
          budget: budget,
          spent: spent,
        );
      },
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetData budget;
  final double spent;

  const _BudgetCard({
    required this.budget,
    required this.spent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
    final remaining = budget.amount - spent;

    TrafficLightStatus status;
    if (percentage >= 100) {
      status = TrafficLightStatus.exceeded;
    } else if (percentage >= 80) {
      status = TrafficLightStatus.warning;
    } else {
      status = TrafficLightStatus.safe;
    }

    String categoryName = 'Sin categoría';
    String? categoryIcon;

    categoriesAsync.whenData((categories) {
      final category = categories.where((c) => c.id == budget.categoryId).firstOrNull;
      if (category != null) {
        categoryName = category.name;
        categoryIcon = category.icon;
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBudgetDetail(context, budget, spent, categoryName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                    child: categoryIcon != null
                        ? Text(categoryIcon!, style: const TextStyle(fontSize: 20))
                        : Icon(Icons.category, color: _getStatusColor(status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${currencyFormat.format(spent)} de ${currencyFormat.format(budget.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                      Text(
                        remaining >= 0
                            ? 'Quedan ${currencyFormat.format(remaining)}'
                            : 'Excedido ${currencyFormat.format(remaining.abs())}',
                        style: TextStyle(
                          fontSize: 11,
                          color: remaining >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_getStatusColor(status)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TrafficLightStatus status) {
    switch (status) {
      case TrafficLightStatus.safe:
        return Colors.green;
      case TrafficLightStatus.warning:
        return Colors.orange;
      case TrafficLightStatus.exceeded:
        return Colors.red;
    }
  }

  void _showBudgetDetail(
    BuildContext context,
    BudgetData budget,
    double spent,
    String categoryName,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _BudgetDetailSheet(
        budget: budget,
        spent: spent,
        categoryName: categoryName,
      ),
    );
  }
}

class _BudgetDetailSheet extends ConsumerWidget {
  final BudgetData budget;
  final double spent;
  final String categoryName;

  const _BudgetDetailSheet({
    required this.budget,
    required this.spent,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
    final remaining = budget.amount - spent;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.savings,
            label: 'Presupuesto',
            value: currencyFormat.format(budget.amount),
          ),
          _DetailRow(
            icon: Icons.shopping_cart,
            label: 'Gastado',
            value: currencyFormat.format(spent),
          ),
          _DetailRow(
            icon: Icons.account_balance_wallet,
            label: 'Disponible',
            value: currencyFormat.format(remaining),
            valueColor: remaining >= 0 ? Colors.green : Colors.red,
          ),
          _DetailRow(
            icon: Icons.percent,
            label: 'Porcentaje',
            value: '${percentage.toStringAsFixed(1)}%',
            valueColor: percentage >= 100
                ? Colors.red
                : percentage >= 80
                    ? Colors.orange
                    : Colors.green,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditBudgetDialog(context, ref, budget);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteBudget(context, ref),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    BudgetData budget,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EditBudgetDialog(
        budget: budget,
        categoryName: categoryName,
      ),
    );
  }

  Future<void> _confirmDeleteBudget(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: Text(
          '¿Estás seguro de eliminar el presupuesto de "$categoryName"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(budgetsNotifierProvider(budget.month, budget.year).notifier)
            .deleteBudget(budget.id);

        if (context.mounted) {
          Navigator.pop(context);
          ref.invalidate(periodBudgetsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presupuesto eliminado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Diálogo para editar presupuesto
class _EditBudgetDialog extends ConsumerStatefulWidget {
  final BudgetData budget;
  final String categoryName;

  const _EditBudgetDialog({
    required this.budget,
    required this.categoryName,
  });

  @override
  ConsumerState<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends ConsumerState<_EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget.amount.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Presupuesto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar categoría (no editable)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo de monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto mensual',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _updateBudget,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _updateBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    try {
      await ref
          .read(budgetsNotifierProvider(
            widget.budget.month,
            widget.budget.year,
          ).notifier)
          .updateBudget(
            id: widget.budget.id,
            amount: amount,
          );

      if (mounted) {
        ref.invalidate(periodBudgetsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presupuesto actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para agregar presupuesto
class _AddBudgetDialog extends ConsumerStatefulWidget {
  const _AddBudgetDialog();

  @override
  ConsumerState<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return AlertDialog(
      title: const Text('Nuevo Presupuesto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selector de categoría
            categoriesAsync.when(
              data: (categories) {
                // Solo mostrar categorías hoja (sin hijos)
                final leafCategories = categories.where((c) => c.parentId != null).toList();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedCategoryId,
                  items: leafCategories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        if (c.icon != null) ...[
                          Text(c.icon!),
                          const SizedBox(width: 8),
                        ],
                        Text(c.name),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Selecciona una categoría';
                    return null;
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Campo de monto
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto mensual',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveBudget,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final period = ref.read(budgetPeriodProvider);

    try {
      await ref
          .read(budgetsNotifierProvider(period.month, period.year).notifier)
          .createBudget(
            categoryId: _selectedCategoryId!,
            amount: amount,
          );

      if (mounted) {
        ref.invalidate(periodBudgetsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presupuesto creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear presupuesto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
