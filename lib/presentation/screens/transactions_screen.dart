import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/providers.dart';
import '../../data/local/database.dart';
import 'transaction_form_screen.dart';

/// Provider para el filtro de tipo de transacción
final transactionTypeFilterProvider = StateProvider<String?>((ref) => null);

/// Provider para el período seleccionado
final selectedPeriodProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0),
  );
});

/// Provider de transacciones filtradas
final filteredTransactionsProvider = FutureProvider<List<TransactionEntry>>((ref) async {
  final dao = ref.watch(transactionsDaoProvider);
  final typeFilter = ref.watch(transactionTypeFilterProvider);
  final period = ref.watch(selectedPeriodProvider);

  final transactions = await dao.getTransactionsInPeriod(
    period.start,
    period.end,
  );

  if (typeFilter == null) {
    return transactions;
  }
  return transactions.where((t) => t.type == typeFilter).toList();
});

/// Pantalla de listado de transacciones
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final typeFilter = ref.watch(transactionTypeFilterProvider);
    final period = ref.watch(selectedPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectPeriod(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(filteredTransactionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de tipo
          _TypeFilterChips(
            selectedType: typeFilter,
            onTypeSelected: (type) {
              ref.read(transactionTypeFilterProvider.notifier).state = type;
            },
          ),

          // Indicador de período
          _PeriodIndicator(period: period),

          // Lista de transacciones
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) => _TransactionsList(transactions: transactions),
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
                      onPressed: () => ref.invalidate(filteredTransactionsProvider),
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

  Future<void> _selectPeriod(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: ref.read(selectedPeriodProvider),
      locale: const Locale('es', 'CO'),
    );

    if (result != null) {
      ref.read(selectedPeriodProvider.notifier).state = result;
    }
  }
}

class _TypeFilterChips extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onTypeSelected;

  const _TypeFilterChips({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selectedType == null,
            onSelected: (_) => onTypeSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Gastos'),
            selected: selectedType == 'expense',
            onSelected: (_) => onTypeSelected(selectedType == 'expense' ? null : 'expense'),
            avatar: selectedType == 'expense'
                ? null
                : const Icon(Icons.arrow_upward, size: 18, color: Colors.red),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Ingresos'),
            selected: selectedType == 'income',
            onSelected: (_) => onTypeSelected(selectedType == 'income' ? null : 'income'),
            avatar: selectedType == 'income'
                ? null
                : const Icon(Icons.arrow_downward, size: 18, color: Colors.green),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Transferencias'),
            selected: selectedType == 'transfer',
            onSelected: (_) => onTypeSelected(selectedType == 'transfer' ? null : 'transfer'),
            avatar: selectedType == 'transfer'
                ? null
                : const Icon(Icons.swap_horiz, size: 18, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class _PeriodIndicator extends StatelessWidget {
  final DateTimeRange period;

  const _PeriodIndicator({required this.period});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM', 'es_CO');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16),
          const SizedBox(width: 8),
          Text(
            '${dateFormat.format(period.start)} - ${dateFormat.format(period.end)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TransactionsList extends ConsumerWidget {
  final List<TransactionEntry> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay movimientos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca + para agregar uno',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Agrupar por fecha
    final grouped = _groupByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return _DateGroup(
          date: entry.key,
          transactions: entry.value,
        );
      },
    );
  }

  Map<DateTime, List<TransactionEntry>> _groupByDate(List<TransactionEntry> transactions) {
    final grouped = <DateTime, List<TransactionEntry>>{};

    for (final tx in transactions) {
      final date = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      grouped.putIfAbsent(date, () => []).add(tx);
    }

    // Ordenar por fecha descendente
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionEntry> transactions;

  const _DateGroup({
    required this.date,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM', 'es_CO');
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Hoy';
    } else if (isYesterday) {
      dateLabel = 'Ayer';
    } else {
      dateLabel = dateFormat.format(date);
    }

    // Calcular totales del día
    double dayIncome = 0;
    double dayExpense = 0;

    for (final tx in transactions) {
      if (tx.type == 'income') {
        dayIncome += tx.amount;
      } else if (tx.type == 'expense') {
        dayExpense += tx.amount;
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (dayIncome > 0) ...[
                    Text(
                      '+${currencyFormat.format(dayIncome)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (dayExpense > 0)
                    Text(
                      '-${currencyFormat.format(dayExpense)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ...transactions.map((tx) => _TransactionTile(transaction: tx)),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionEntry transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    Color amountColor;
    String prefix;
    IconData typeIcon;

    switch (transaction.type) {
      case 'income':
        amountColor = Colors.green;
        prefix = '+';
        typeIcon = Icons.arrow_downward;
        break;
      case 'expense':
        amountColor = Colors.red;
        prefix = '-';
        typeIcon = Icons.arrow_upward;
        break;
      case 'transfer':
        amountColor = Colors.blue;
        prefix = '';
        typeIcon = Icons.swap_horiz;
        break;
      default:
        amountColor = Colors.grey;
        prefix = '';
        typeIcon = Icons.help_outline;
    }

    // Obtener categoría
    String categoryName = '';
    String? categoryIcon;

    categoriesAsync.whenData((categories) {
      final category = categories.where((c) => c.id == transaction.categoryId).firstOrNull;
      if (category != null) {
        categoryName = category.name;
        categoryIcon = category.icon;
      }
    });

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.2),
        child: categoryIcon != null
            ? Text(categoryIcon!, style: const TextStyle(fontSize: 20))
            : Icon(typeIcon, color: amountColor),
      ),
      title: Text(
        transaction.description ?? categoryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        categoryName,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Text(
        '$prefix${currencyFormat.format(transaction.amount)}',
        style: TextStyle(
          color: amountColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () => _showTransactionDetail(context, transaction),
    );
  }

  void _showTransactionDetail(BuildContext context, TransactionEntry tx) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TransactionDetailSheet(transaction: tx),
    );
  }
}

class _TransactionDetailSheet extends ConsumerStatefulWidget {
  final TransactionEntry transaction;

  const _TransactionDetailSheet({required this.transaction});

  @override
  ConsumerState<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState
    extends ConsumerState<_TransactionDetailSheet> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es_CO');

    String categoryName = 'Sin categoría';
    categoriesAsync.whenData((categories) {
      final category = categories
          .where((c) => c.id == widget.transaction.categoryId)
          .firstOrNull;
      if (category != null) {
        categoryName = category.name;
      }
    });

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
                _getTypeLabel(widget.transaction.type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            currencyFormat.format(widget.transaction.amount),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(widget.transaction.type),
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            icon: Icons.category,
            label: 'Categoría',
            value: categoryName,
          ),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Fecha',
            value: dateFormat.format(widget.transaction.transactionDate),
          ),
          if (widget.transaction.description != null &&
              widget.transaction.description!.isNotEmpty)
            _DetailRow(
              icon: Icons.description,
              label: 'Descripción',
              value: widget.transaction.description!,
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editTransaction(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDeleting ? null : () => _confirmDelete(context),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete, color: Colors.red),
                  label: Text(
                    _isDeleting ? 'Eliminando...' : 'Eliminar',
                    style: TextStyle(
                      color: _isDeleting ? Colors.grey : Colors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isDeleting ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          transaction: widget.transaction,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: const Text(
          '¿Estás seguro de eliminar esta transacción?\n\n'
          'Esta acción revertirá los cambios en los balances de las cuentas afectadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteTransaction();
    }
  }

  Future<void> _deleteTransaction() async {
    setState(() => _isDeleting = true);

    try {
      final accountingService = ref.read(accountingServiceProvider);
      await accountingService.deleteTransaction(widget.transaction.id);

      // Invalidar providers para refrescar datos
      ref.invalidate(filteredTransactionsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(dashboardSummaryProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Ingreso';
      case 'expense':
        return 'Gasto';
      case 'transfer':
        return 'Transferencia';
      default:
        return 'Movimiento';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
