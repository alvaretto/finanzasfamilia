import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;

import '../../application/providers/database_provider.dart';
import '../../application/providers/categories_provider.dart';
import '../../data/local/database.dart';

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

/// Provider para obtener cuentas activas
final activeAccountsProvider = FutureProvider<List<AccountEntry>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.accounts).get();
});

/// Pantalla de formulario para crear/editar transacciones
class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntry? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _numberFormat = NumberFormat('#,##0', 'es_CO');

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _initializeForEdit();
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
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _saveTransaction,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Actualizar' : 'Guardar'),
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

    final categoriesAsync = ref.watch(categoriesByTypeProvider(categoryType));

    return categoriesAsync.when(
      data: (categories) {
        final rootCategories =
            categories.where((c) => c.parentId == null).toList();

        return DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: rootCategories.map((category) {
            return DropdownMenuItem(
              value: category.id,
              child: Row(
                children: [
                  Text(
                    category.icon ?? '📁',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            ref.read(selectedCategoryIdProvider.notifier).state = value;
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona una categoría';
            }
            return null;
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error cargando categorías'),
    );
  }

  Widget _buildAccountSelectors(String transactionType) {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return accountsAsync.when(
      data: (accounts) {
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
      value: selectedId,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Row(
            children: [
              Text(
                account.icon ?? '💰',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(account.name)),
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final transactionType = ref.read(transactionTypeProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final categoryId = ref.read(selectedCategoryIdProvider);
    final fromAccountId = ref.read(selectedFromAccountIdProvider);
    final toAccountId = ref.read(selectedToAccountIdProvider);

    // Validaciones adicionales para transferencias
    if (transactionType == 'transfer') {
      if (fromAccountId == toAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las cuentas origen y destino deben ser diferentes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final amount =
        double.parse(_amountController.text.replaceAll('.', ''));
    final description = _descriptionController.text.trim();

    final db = ref.read(appDatabaseProvider);
    final transactionsDao = ref.read(transactionsDaoProvider);

    try {
      if (isEditing) {
        // Actualizar transacción existente
        await (db.update(db.transactions)
              ..where((t) => t.id.equals(widget.transaction!.id)))
            .write(TransactionsCompanion(
          type: Value(transactionType),
          amount: Value(amount),
          description: Value(description.isEmpty ? null : description),
          categoryId: Value(categoryId!),
          fromAccountId: Value(
            transactionType == 'income' ? null : fromAccountId,
          ),
          toAccountId: Value(
            transactionType == 'expense' ? null : toAccountId,
          ),
          transactionDate: Value(selectedDate),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        // Crear nueva transacción
        await transactionsDao.insertTransaction(TransactionsCompanion(
          id: Value(const Uuid().v4()),
          type: Value(transactionType),
          amount: Value(amount),
          description: Value(description.isEmpty ? null : description),
          categoryId: Value(categoryId!),
          fromAccountId: Value(
            transactionType == 'income' ? null : fromAccountId,
          ),
          toAccountId: Value(
            transactionType == 'expense' ? null : toAccountId,
          ),
          transactionDate: Value(selectedDate),
          isConfirmed: const Value(true),
          hasDetails: const Value(false),
          itemCount: const Value(1),
          syncStatus: const Value('pending'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Transacción actualizada'
                  : 'Transacción registrada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
