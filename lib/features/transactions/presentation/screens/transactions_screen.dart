import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/search_filter_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final dateFormat = DateFormat('EEEE d', 'es');
  final monthFormat = DateFormat('MMMM yyyy', 'es');

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);

    // Escuchar errores
    ref.listen<TransactionsState>(transactionsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(transactionsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          if (txState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Consumer(
            builder: (context, ref, _) {
              final filters = ref.watch(transactionFiltersProvider);
              final count = filters.activeFilterCount;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFiltersSheet(context),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: txState.isSyncing
                ? null
                : () => ref.read(transactionsProvider.notifier).syncTransactions(),
          ),
        ],
      ),
      body: txState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: TransactionSearchBar(),
                ),

                // Resumen del periodo
                _buildPeriodSummary(context, txState),

                // Selector de mes
                _buildMonthSelector(context, txState),

                // Lista de transacciones filtradas
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final filteredTransactions = ref.watch(filteredTransactionsProvider);
                      final filters = ref.watch(transactionFiltersProvider);

                      if (txState.transactions.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      if (filteredTransactions.isEmpty && filters.hasActiveFilters) {
                        return SingleChildScrollView(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                const Text('Sin resultados'),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: () {
                                    ref.read(transactionFiltersProvider.notifier).state =
                                        const TransactionFilters();
                                  },
                                  child: const Text('Limpiar filtros'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(transactionsProvider.notifier)
                            .syncTransactions(),
                        child: _buildTransactionsList(filteredTransactions),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }

  Widget _buildPeriodSummary(BuildContext context, TransactionsState state) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              label: 'Ingresos',
              amount: state.totalIncome,
              color: AppColors.income,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildSummaryCard(
              context,
              label: 'Gastos',
              amount: state.totalExpenses,
              color: AppColors.expense,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
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
                  Text(
                    currencyFormat.format(amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
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

  Widget _buildMonthSelector(BuildContext context, TransactionsState state) {
    final from = state.fromDate ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          TextButton(
            onPressed: () => _showMonthPicker(context),
            child: Text(
              monthFormat.format(from).toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _canGoForward() ? () => _changeMonth(1) : null,
          ),
        ],
      ),
    );
  }

  bool _canGoForward() {
    final state = ref.read(transactionsProvider);
    final from = state.fromDate ?? DateTime.now();
    final now = DateTime.now();
    return from.year < now.year ||
        (from.year == now.year && from.month < now.month);
  }

  void _changeMonth(int delta) {
    final state = ref.read(transactionsProvider);
    final from = state.fromDate ?? DateTime.now();
    final newMonth = DateTime(from.year, from.month + delta, 1);
    final newEnd = DateTime(newMonth.year, newMonth.month + 1, 0, 23, 59, 59);
    ref.read(transactionsProvider.notifier).setDateRange(newMonth, newEnd);
  }

  void _showMonthPicker(BuildContext context) async {
    final state = ref.read(transactionsProvider);
    final from = state.fromDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('es'),
    );

    if (picked != null) {
      final newFrom = DateTime(picked.year, picked.month, 1);
      final newTo = DateTime(picked.year, picked.month + 1, 0, 23, 59, 59);
      ref.read(transactionsProvider.notifier).setDateRange(newFrom, newTo);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sin transacciones',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No hay transacciones en este periodo.\nAgrega tu primera transaccion.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => _showAddTransaction(context),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Transaccion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    // Agrupar por fecha
    final groupedByDate = <DateTime, List<TransactionModel>>{};
    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTransactions = groupedByDate[date]!;
        final dayTotal = dayTransactions.fold<double>(
          0,
          (sum, tx) => sum + tx.signedAmount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de fecha
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateHeader(date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  Text(
                    currencyFormat.format(dayTotal.abs()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dayTotal >= 0 ? AppColors.income : AppColors.expense,
                        ),
                  ),
                ],
              ),
            ),
            // Transacciones del dia
            ...dayTransactions.map((tx) => _buildTransactionItem(context, tx)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Hoy';
    if (date == yesterday) return 'Ayer';
    return dateFormat.format(date);
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () => _showTransactionDetail(context, tx),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icono de categoria
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _getTransactionColor(tx).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _getTransactionIcon(tx),
                  color: _getTransactionColor(tx),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Descripcion y categoria
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description ?? tx.categoryName ?? tx.type.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (tx.accountName != null)
                          Text(
                            tx.accountName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        if (isTransfer && tx.transferToAccountName != null) ...[
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          Text(
                            tx.transferToAccountName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Monto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTransactionColor(tx),
                        ),
                  ),
                  if (!tx.isSynced)
                    Icon(
                      Icons.cloud_off,
                      size: 12,
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTransactionColor(TransactionModel tx) {
    switch (tx.type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.info;
    }
  }

  IconData _getTransactionIcon(TransactionModel tx) {
    if (tx.type == TransactionType.transfer) return Icons.swap_horiz;
    if (tx.categoryIcon != null) {
      return _getCategoryIcon(tx.categoryIcon!);
    }
    return tx.type == TransactionType.income
        ? Icons.arrow_downward
        : Icons.arrow_upward;
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'power': Icons.power,
      'favorite': Icons.favorite,
      'movie': Icons.movie,
      'shopping_bag': Icons.shopping_bag,
      'school': Icons.school,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'laptop': Icons.laptop,
      'trending_up': Icons.trending_up,
      'card_giftcard': Icons.card_giftcard,
      'add_circle': Icons.add_circle,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  void _showAddTransaction(BuildContext context, [TransactionType? type]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddTransactionSheet(initialType: type),
    );
  }

  void _showTransactionDetail(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TransactionDetailSheet(transaction: tx),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SearchFilterSheet(),
    );
  }
}

/// Sheet de detalle de transaccion
class _TransactionDetailSheet extends ConsumerWidget {
  final TransactionModel transaction;

  const _TransactionDetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            '${transaction.type == TransactionType.income ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(transaction.type),
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            transaction.type.displayName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _getTypeColor(transaction.type),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (transaction.description != null)
                    _buildDetailRow(context, Icons.short_text, 'Descripcion', transaction.description!),
                  _buildDetailRow(context, Icons.calendar_today, 'Fecha', dateFormat.format(transaction.date)),
                  if (transaction.accountName != null)
                    _buildDetailRow(context, Icons.account_balance_wallet, 'Cuenta', transaction.accountName!),
                  if (transaction.categoryName != null)
                    _buildDetailRow(context, Icons.category, 'Categoria', transaction.categoryName!),
                  if (transaction.notes != null && transaction.notes!.isNotEmpty)
                    _buildDetailRow(context, Icons.notes, 'Notas', transaction.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => AddTransactionSheet(transaction: transaction),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context, ref),
                  icon: Icon(Icons.delete, color: AppColors.error),
                  label: Text('Eliminar', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          )),
          const Spacer(),
          Flexible(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar transaccion'),
        content: const Text('El balance de la cuenta se ajustara automaticamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(transactionsProvider.notifier).deleteTransaction(transaction);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Transaccion eliminada'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income: return AppColors.income;
      case TransactionType.expense: return AppColors.expense;
      case TransactionType.transfer: return AppColors.info;
    }
  }
}
