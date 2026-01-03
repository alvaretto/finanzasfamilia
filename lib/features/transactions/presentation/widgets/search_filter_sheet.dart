import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

/// Filtros de transacciones
class TransactionFilters {
  final String? searchQuery;
  final TransactionType? type;
  final String? accountId;
  final int? categoryId;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilters({
    this.searchQuery,
    this.type,
    this.accountId,
    this.categoryId,
    this.minAmount,
    this.maxAmount,
  });

  bool get hasActiveFilters =>
      searchQuery != null ||
      type != null ||
      accountId != null ||
      categoryId != null ||
      minAmount != null ||
      maxAmount != null;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (type != null) count++;
    if (accountId != null) count++;
    if (categoryId != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  TransactionFilters copyWith({
    String? searchQuery,
    TransactionType? type,
    String? accountId,
    int? categoryId,
    double? minAmount,
    double? maxAmount,
    bool clearSearch = false,
    bool clearType = false,
    bool clearAccount = false,
    bool clearCategory = false,
    bool clearAmount = false,
  }) {
    return TransactionFilters(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      type: clearType ? null : (type ?? this.type),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minAmount: clearAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  /// Aplicar filtros a una lista de transacciones
  List<TransactionModel> apply(List<TransactionModel> transactions) {
    var result = transactions;

    // Búsqueda por texto
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((tx) {
        return (tx.description?.toLowerCase().contains(query) ?? false) ||
            (tx.categoryName?.toLowerCase().contains(query) ?? false) ||
            (tx.accountName?.toLowerCase().contains(query) ?? false) ||
            (tx.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtrar por tipo
    if (type != null) {
      result = result.where((tx) => tx.type == type).toList();
    }

    // Filtrar por cuenta
    if (accountId != null) {
      result = result.where((tx) => tx.accountId == accountId).toList();
    }

    // Filtrar por categoría
    if (categoryId != null) {
      result = result.where((tx) => tx.categoryId == categoryId).toList();
    }

    // Filtrar por monto mínimo
    if (minAmount != null) {
      result = result.where((tx) => tx.amount >= minAmount!).toList();
    }

    // Filtrar por monto máximo
    if (maxAmount != null) {
      result = result.where((tx) => tx.amount <= maxAmount!).toList();
    }

    return result;
  }
}

/// Provider de filtros
final transactionFiltersProvider =
    StateProvider<TransactionFilters>((ref) => const TransactionFilters());

/// Provider de transacciones filtradas
final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider).transactions;
  final filters = ref.watch(transactionFiltersProvider);
  return filters.apply(transactions);
});

/// Sheet de filtros
class SearchFilterSheet extends ConsumerStatefulWidget {
  const SearchFilterSheet({super.key});

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  TransactionType? _selectedType;
  String? _selectedAccountId;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(transactionFiltersProvider);
    _selectedType = filters.type;
    _selectedAccountId = filters.accountId;
    _selectedCategoryId = filters.categoryId;
    if (filters.minAmount != null) {
      _minAmountController.text = filters.minAmount!.toStringAsFixed(0);
    }
    if (filters.maxAmount != null) {
      _maxAmountController.text = filters.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    double? minAmount;
    double? maxAmount;

    if (_minAmountController.text.isNotEmpty) {
      minAmount = double.tryParse(_minAmountController.text);
    }
    if (_maxAmountController.text.isNotEmpty) {
      maxAmount = double.tryParse(_maxAmountController.text);
    }

    ref.read(transactionFiltersProvider.notifier).state = TransactionFilters(
      searchQuery: ref.read(transactionFiltersProvider).searchQuery,
      type: _selectedType,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );

    Navigator.pop(context);
  }

  void _clearFilters() {
    ref.read(transactionFiltersProvider.notifier).state =
        const TransactionFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(activeAccountsProvider);
    final txState = ref.watch(transactionsProvider);
    final categories = txState.categories;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Filters
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                // Tipo de transacción
                Text(
                  'Tipo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      isSelected: _selectedType == null,
                      onSelected: () => setState(() => _selectedType = null),
                    ),
                    _FilterChip(
                      label: 'Gastos',
                      isSelected: _selectedType == TransactionType.expense,
                      color: AppColors.expense,
                      onSelected: () => setState(
                          () => _selectedType = TransactionType.expense),
                    ),
                    _FilterChip(
                      label: 'Ingresos',
                      isSelected: _selectedType == TransactionType.income,
                      color: AppColors.income,
                      onSelected: () => setState(
                          () => _selectedType = TransactionType.income),
                    ),
                    _FilterChip(
                      label: 'Transferencias',
                      isSelected: _selectedType == TransactionType.transfer,
                      color: AppColors.info,
                      onSelected: () => setState(
                          () => _selectedType = TransactionType.transfer),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Cuenta
                Text(
                  'Cuenta',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    hintText: 'Todas las cuentas',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las cuentas'),
                    ),
                    ...accounts.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedAccountId = value),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Categoría
                Text(
                  'Categoría',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    hintText: 'Todas las categorías',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Rango de monto
                Text(
                  'Rango de monto',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Mínimo',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Máximo',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: _applyFilters,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Aplicar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }
}

/// Barra de búsqueda para transacciones
class TransactionSearchBar extends ConsumerWidget {
  const TransactionSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionFiltersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar transacciones...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: filters.searchQuery != null && filters.searchQuery!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(transactionFiltersProvider.notifier).state =
                        filters.copyWith(clearSearch: true);
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        onChanged: (value) {
          ref.read(transactionFiltersProvider.notifier).state =
              filters.copyWith(searchQuery: value.isEmpty ? null : value, clearSearch: value.isEmpty);
        },
      ),
    );
  }
}
