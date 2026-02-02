import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/database_provider.dart';
import '../../application/providers/accounting_provider.dart';
import '../../application/providers/dashboard_provider.dart';
import '../../data/local/database.dart';
import '../widgets/hierarchical_category_selector.dart';
import 'transactions_screen.dart' show filteredTransactionsProvider;

/// Provider para el tipo de transacción seleccionado
final transactionTypeProvider = StateProvider<String>((ref) => 'expense');

/// Provider para la fecha seleccionada
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provider para la categoría seleccionada
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Provider para la cuenta origen seleccionada
final selectedFromAccountIdProvider = StateProvider<String?>((ref) => null);

/// Provider para la cuenta destino seleccionada (transferencias)
final selectedToAccountIdProvider = StateProvider<String?>((ref) => null);

/// Provider para el nivel de satisfacción del gasto (solo expenses)
final selectedSatisfactionProvider = StateProvider<String?>((ref) => null);

/// Provider para obtener cuentas activas para el formulario de transacciones
/// Usa el DAO para obtener cuentas ordenadas por nombre
final transactionFormAccountsProvider =
    FutureProvider<List<AccountEntry>>((ref) async {
  final accountsDao = ref.watch(accountsDaoProvider);
  return accountsDao.getActiveAccounts();
});

/// Pantalla de formulario para crear/editar transacciones
class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntry? transaction;
  final String? initialType;
  final double? initialAmount;
  final String? initialDescription;

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.initialType,
    this.initialAmount,
    this.initialDescription,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0', 'es_CO');
  bool _isSaving = false;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _initializeForEdit();
    } else {
      _initializeNew();
    }
  }

  void _initializeNew() {
    // Pre-llenar monto si se proporciona
    if (widget.initialAmount != null) {
      _amountController.text = _numberFormat.format(widget.initialAmount);
    }
    // Pre-llenar descripción si se proporciona
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    // Inicializar tipo
    if (widget.initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(transactionTypeProvider.notifier).state = widget.initialType!;
      });
    }
  }

  void _initializeForEdit() {
    final tx = widget.transaction!;
    _amountController.text = _numberFormat.format(tx.amount);
    _descriptionController.text = tx.description ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionTypeProvider.notifier).state = tx.type;
      ref.read(selectedDateProvider.notifier).state = tx.transactionDate;
      ref.read(selectedCategoryIdProvider.notifier).state = tx.categoryId;
      ref.read(selectedFromAccountIdProvider.notifier).state = tx.fromAccountId;
      ref.read(selectedToAccountIdProvider.notifier).state = tx.toAccountId;
      ref.read(selectedSatisfactionProvider.notifier).state =
          tx.satisfactionLevel;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = ref.watch(transactionTypeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Transacción' : 'Nueva Transacción'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de tipo
            _buildTypeSelector(transactionType, colorScheme),
            const SizedBox(height: 24),

            // Campo de monto
            _buildAmountField(colorScheme),
            const SizedBox(height: 16),

            // Selector de fecha
            _buildDateSelector(selectedDate),
            const SizedBox(height: 16),

            // Selector de categoría
            _buildCategorySelector(transactionType),
            const SizedBox(height: 16),

            // Selectores de cuenta
            _buildAccountSelectors(transactionType),
            const SizedBox(height: 16),

            // Campo de descripción
            _buildDescriptionField(),

            // Selector de satisfacción (solo para gastos)
            if (transactionType == 'expense') ...[
              const SizedBox(height: 16),
              _buildSatisfactionSelector(),
            ],
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveTransaction,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving
                  ? 'Guardando...'
                  : (isEditing ? 'Actualizar' : 'Guardar')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(String transactionType, ColorScheme colorScheme) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'expense',
          label: const Text('Gasto'),
          icon: Icon(
            Icons.arrow_upward,
            color: transactionType == 'expense' ? Colors.white : Colors.red,
          ),
        ),
        ButtonSegment(
          value: 'income',
          label: const Text('Ingreso'),
          icon: Icon(
            Icons.arrow_downward,
            color: transactionType == 'income' ? Colors.white : Colors.green,
          ),
        ),
        ButtonSegment(
          value: 'transfer',
          label: const Text('Transfer.'),
          icon: Icon(
            Icons.swap_horiz,
            color: transactionType == 'transfer' ? Colors.white : Colors.blue,
          ),
        ),
      ],
      selected: {transactionType},
      onSelectionChanged: (selected) {
        ref.read(transactionTypeProvider.notifier).state = selected.first;
        // Limpiar categoría al cambiar tipo
        ref.read(selectedCategoryIdProvider.notifier).state = null;
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return switch (transactionType) {
              'expense' => Colors.red,
              'income' => Colors.green,
              'transfer' => Colors.blue,
              _ => colorScheme.primary,
            };
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildAmountField(ColorScheme colorScheme) {
    final transactionType = ref.watch(transactionTypeProvider);
    final amountColor = switch (transactionType) {
      'expense' => Colors.red,
      'income' => Colors.green,
      'transfer' => Colors.blue,
      _ => colorScheme.primary,
    };

    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsSeparatorFormatter(),
      ],
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: amountColor,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: 'Monto',
        prefixText: '\$ ',
        prefixStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
        border: const OutlineInputBorder(),
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa un monto';
        }
        final numValue = double.tryParse(value.replaceAll('.', ''));
        if (numValue == null || numValue <= 0) {
          return 'Monto inválido';
        }
        return null;
      },
    );
  }

  Widget _buildDateSelector(DateTime selectedDate) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es_CO');

    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: const Text('Fecha'),
      subtitle: Text(dateFormat.format(selectedDate)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'CO'),
        );
        if (picked != null) {
          ref.read(selectedDateProvider.notifier).state = picked;
        }
      },
    );
  }

  Widget _buildCategorySelector(String transactionType) {
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    // Mapear tipo de transacción a tipo de categoría
    final categoryType = switch (transactionType) {
      'expense' => 'expense',
      'income' => 'income',
      'transfer' => 'asset', // Para transferencias usamos categorías de activos
      _ => 'expense',
    };

    // Usar selector jerárquico para mejor UX
    return HierarchicalCategorySelector(
      categoryType: categoryType,
      selectedCategoryId: selectedCategoryId,
      showOnlyLeaves: true, // Solo permitir seleccionar subcategorías
      onCategorySelected: (category) {
        ref.read(selectedCategoryIdProvider.notifier).state = category.id;
      },
    );
  }

  Widget _buildAccountSelectors(String transactionType) {
    final accountsAsync = ref.watch(transactionFormAccountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        // Si no hay cuentas, mostrar mensaje de error
        if (accounts.isEmpty) {
          return Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay cuentas disponibles. Ve a Configuración > Cuentas para crear una.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (transactionType == 'transfer') {
          // Para transferencias: cuenta origen y destino
          return Column(
            children: [
              _buildAccountDropdown(
                accounts: accounts,
                label: 'Cuenta origen',
                icon: Icons.account_balance_wallet,
                selectedProvider: selectedFromAccountIdProvider,
                validator: true,
              ),
              const SizedBox(height: 16),
              _buildAccountDropdown(
                accounts: accounts,
                label: 'Cuenta destino',
                icon: Icons.account_balance,
                selectedProvider: selectedToAccountIdProvider,
                validator: true,
              ),
            ],
          );
        } else if (transactionType == 'expense') {
          // Para gastos: solo cuenta origen
          return _buildAccountDropdown(
            accounts: accounts,
            label: 'Cuenta',
            icon: Icons.account_balance_wallet,
            selectedProvider: selectedFromAccountIdProvider,
            validator: true,
          );
        } else {
          // Para ingresos: solo cuenta destino
          return _buildAccountDropdown(
            accounts: accounts,
            label: 'Cuenta',
            icon: Icons.account_balance_wallet,
            selectedProvider: selectedToAccountIdProvider,
            validator: true,
          );
        }
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error cargando cuentas'),
    );
  }

  Widget _buildAccountDropdown({
    required List<AccountEntry> accounts,
    required String label,
    required IconData icon,
    required StateProvider<String?> selectedProvider,
    required bool validator,
  }) {
    final selectedId = ref.watch(selectedProvider);

    return DropdownButtonFormField<String>(
      key: ValueKey('${selectedProvider.hashCode}_$selectedId'),
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.icon ?? '💰',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(account.name)),
              const SizedBox(width: 8),
              Text(
                NumberFormat.currency(locale: 'es_CO', symbol: '\$')
                    .format(account.balance),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        ref.read(selectedProvider.notifier).state = value;
      },
      validator: validator
          ? (value) {
              if (value == null) {
                return 'Selecciona una cuenta';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Descripción (opcional)',
        prefixIcon: Icon(Icons.notes),
        border: OutlineInputBorder(),
        hintText: 'Ej: Almuerzo en restaurante',
      ),
    );
  }

  Widget _buildSatisfactionSelector() {
    final satisfaction = ref.watch(selectedSatisfactionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Satisfacción con la compra (opcional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String?>(
          segments: const [
            ButtonSegment(
              value: 'low',
              label: Text('Baja'),
              icon: Icon(Icons.sentiment_very_dissatisfied),
            ),
            ButtonSegment(
              value: 'medium',
              label: Text('Media'),
              icon: Icon(Icons.sentiment_neutral),
            ),
            ButtonSegment(
              value: 'high',
              label: Text('Alta'),
              icon: Icon(Icons.sentiment_very_satisfied),
            ),
            ButtonSegment(
              value: 'neutral',
              label: Text('N/A'),
              icon: Icon(Icons.remove_circle_outline),
            ),
          ],
          selected: satisfaction != null ? {satisfaction} : {},
          emptySelectionAllowed: true,
          onSelectionChanged: (selected) {
            ref.read(selectedSatisfactionProvider.notifier).state =
                selected.isEmpty ? null : selected.first;
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final transactionType = ref.read(transactionTypeProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final categoryId = ref.read(selectedCategoryIdProvider);
    final fromAccountId = ref.read(selectedFromAccountIdProvider);
    final toAccountId = ref.read(selectedToAccountIdProvider);
    final satisfactionLevel = ref.read(selectedSatisfactionProvider);

    // Validaciones adicionales para transferencias
    if (transactionType == 'transfer') {
      if (fromAccountId == toAccountId) {
        setState(() => _isSaving = false);
        _showError('Las cuentas origen y destino deben ser diferentes');
        return;
      }
      if (fromAccountId == null || toAccountId == null) {
        setState(() => _isSaving = false);
        _showError('Selecciona ambas cuentas para la transferencia');
        return;
      }
    }

    // Validar cuenta según tipo
    if (transactionType == 'expense' && fromAccountId == null) {
      setState(() => _isSaving = false);
      _showError('Selecciona una cuenta de origen');
      return;
    }
    if (transactionType == 'income' && toAccountId == null) {
      setState(() => _isSaving = false);
      _showError('Selecciona una cuenta de destino');
      return;
    }

    // Validar categoría (obligatoria para gastos e ingresos, no para transferencias)
    if (transactionType != 'transfer' && categoryId == null) {
      setState(() => _isSaving = false);
      _showError('Selecciona una categoría');
      return;
    }

    final amount = double.parse(_amountController.text.replaceAll('.', ''));
    final description = _descriptionController.text.trim();

    final accountingService = ref.read(accountingServiceProvider);

    try {
      if (isEditing) {
        // Usar AccountingService para actualizar con reversión de asientos
        await accountingService.updateTransaction(
          transactionId: widget.transaction!.id,
          type: transactionType,
          categoryId: categoryId!,
          amount: amount,
          description: description.isEmpty ? 'Sin descripción' : description,
          date: selectedDate,
          fromAccountId: transactionType == 'income' ? null : fromAccountId,
          toAccountId: transactionType == 'expense' ? null : toAccountId,
        );
      } else {
        // NUEVO: Usar AccountingService para crear transacción con partida doble
        switch (transactionType) {
          case 'expense':
            await accountingService.recordExpense(
              categoryId: categoryId!,
              paymentAccountId: fromAccountId!,
              amount: amount,
              description: description.isEmpty ? 'Gasto' : description,
              date: selectedDate,
              satisfactionLevel: satisfactionLevel,
            );
            break;

          case 'income':
            await accountingService.recordIncome(
              categoryId: categoryId!,
              destinationAccountId: toAccountId!,
              amount: amount,
              description: description.isEmpty ? 'Ingreso' : description,
              date: selectedDate,
            );
            break;

          case 'transfer':
            await accountingService.recordTransfer(
              fromAccountId: fromAccountId!,
              toAccountId: toAccountId!,
              amount: amount,
              description: description.isEmpty ? 'Transferencia' : description,
              date: selectedDate,
            );
            break;
        }
      }

      if (mounted) {
        // Feedback háptico de éxito
        HapticFeedback.mediumImpact();

        // Invalidar providers para refrescar datos
        ref.invalidate(activeAccountsProvider);
        ref.invalidate(totalBalanceProvider);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(filteredTransactionsProvider);

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Transacción actualizada'
                  : 'Transacción registrada con asientos contables',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta transacción? '
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

    if (confirmed == true && mounted) {
      final transactionsDao = ref.read(transactionsDaoProvider);
      await transactionsDao.deleteTransaction(widget.transaction!.id);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// Formateador de miles para el campo de monto
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  final _numberFormat = NumberFormat('#,##0', 'es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numValue = int.tryParse(newValue.text.replaceAll('.', ''));
    if (numValue == null) {
      return oldValue;
    }

    final formatted = _numberFormat.format(numValue);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
