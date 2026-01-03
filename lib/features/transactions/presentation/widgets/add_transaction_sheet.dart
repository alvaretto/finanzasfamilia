import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? transaction; // Para editar
  final TransactionType? initialType;

  const AddTransactionSheet({
    super.key,
    this.transaction,
    this.initialType,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  late TransactionType _selectedType;
  String? _selectedAccountId;
  String? _selectedTransferAccountId;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _descriptionController.text = tx.description ?? '';
      _notesController.text = tx.notes ?? '';
      _selectedType = tx.type;
      _selectedAccountId = tx.accountId;
      _selectedTransferAccountId = tx.transferToAccountId;
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(activeAccountsProvider);
    final txState = ref.watch(transactionsProvider);
    final categories = _selectedType == TransactionType.income
        ? txState.incomeCategories
        : txState.expenseCategories;

    // Si no hay cuentas, mostrar mensaje para crear una primero
    if (accounts.isEmpty) {
      return _buildNoAccountsMessage(context);
    }

    // Seleccionar primera cuenta si no hay ninguna
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con tipo de transaccion
            _buildHeader(context),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monto grande
                      _buildAmountField(),
                      const SizedBox(height: AppSpacing.lg),

                      // Cuenta
                      _buildAccountSelector(accounts),
                      const SizedBox(height: AppSpacing.md),

                      // Cuenta destino (solo transferencias)
                      if (_selectedType == TransactionType.transfer) ...[
                        _buildTransferAccountSelector(accounts),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Categoria (no para transferencias)
                      if (_selectedType != TransactionType.transfer) ...[
                        _buildCategorySelector(categories),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Descripcion
                      TextFormField(
                        controller: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                          prefixIcon: Icon(Icons.short_text),
                          hintText: 'ej. Compras supermercado',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Fecha
                      _buildDateSelector(),
                      const SizedBox(height: AppSpacing.md),

                      // Notas
                      TextFormField(
                        controller: _notesController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          prefixIcon: Icon(Icons.notes),
                          hintText: 'Detalles adicionales...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Boton guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getTypeColor(),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isEditing ? 'Guardar Cambios' : _getSaveLabel()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  isEditing ? 'Editar Transaccion' : 'Nueva Transaccion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Selector de tipo
          if (!isEditing)
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: const Text('Gasto'),
                  icon: Icon(
                    Icons.arrow_upward,
                    color: _selectedType == TransactionType.expense
                        ? Colors.white
                        : AppColors.expense,
                  ),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: const Text('Ingreso'),
                  icon: Icon(
                    Icons.arrow_downward,
                    color: _selectedType == TransactionType.income
                        ? Colors.white
                        : AppColors.income,
                  ),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: const Text('Transfer'),
                  icon: Icon(
                    Icons.swap_horiz,
                    color: _selectedType == TransactionType.transfer
                        ? Colors.white
                        : AppColors.info,
                  ),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedType = selection.first;
                  _selectedCategoryId = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Center(
      child: IntrinsicWidth(
        child: TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTypeColor(),
              ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            prefixText: '\$ ',
            prefixStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(),
                ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el monto';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Monto invalido';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildAccountSelector(List<AccountModel> accounts) {
    return DropdownButtonFormField<String>(
      value: _selectedAccountId,
      decoration: InputDecoration(
        labelText: _selectedType == TransactionType.transfer ? 'Cuenta origen' : 'Cuenta',
        prefixIcon: const Icon(Icons.account_balance_wallet),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Row(
            children: [
              Icon(
                _getAccountIcon(account.type),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(account.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedAccountId = value);
      },
      validator: (value) {
        if (value == null) return 'Selecciona una cuenta';
        return null;
      },
    );
  }

  Widget _buildTransferAccountSelector(List<AccountModel> accounts) {
    final availableAccounts =
        accounts.where((a) => a.id != _selectedAccountId).toList();

    return DropdownButtonFormField<String>(
      value: _selectedTransferAccountId,
      decoration: const InputDecoration(
        labelText: 'Cuenta destino',
        prefixIcon: Icon(Icons.arrow_forward),
      ),
      items: availableAccounts.map((account) {
        return DropdownMenuItem(
          value: account.id,
          child: Row(
            children: [
              Icon(
                _getAccountIcon(account.type),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(account.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedTransferAccountId = value);
      },
      validator: (value) {
        if (_selectedType == TransactionType.transfer && value == null) {
          return 'Selecciona cuenta destino';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector(List<CategoryModel> categories) {
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Categoria',
        prefixIcon: Icon(Icons.category),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat.id,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _parseColor(cat.color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getCategoryIcon(cat.icon),
                  size: 16,
                  color: _parseColor(cat.color),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(cat.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategoryId = value);
      },
      validator: (value) {
        if (_selectedType != TransactionType.transfer && value == null) {
          return 'Selecciona una categoria';
        }
        return null;
      },
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: const Text('Fecha'),
      subtitle: Text(DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es'),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      bool success;

      if (isEditing) {
        final newTx = widget.transaction!.copyWith(
          accountId: _selectedAccountId!,
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          transferToAccountId: _selectedTransferAccountId,
          isSynced: false,
        );

        success = await ref
            .read(transactionsProvider.notifier)
            .updateTransaction(widget.transaction!, newTx);
      } else {
        success = await ref.read(transactionsProvider.notifier).createTransaction(
              accountId: _selectedAccountId!,
              amount: amount,
              type: _selectedType,
              categoryId: _selectedCategoryId,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              date: _selectedDate,
              notes: _notesController.text.isEmpty
                  ? null
                  : _notesController.text.trim(),
              transferToAccountId: _selectedTransferAccountId,
            );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Transaccion actualizada' : _getSuccessMessage()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getTypeColor() {
    switch (_selectedType) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.info;
    }
  }

  String _getSaveLabel() {
    switch (_selectedType) {
      case TransactionType.income:
        return 'Registrar Ingreso';
      case TransactionType.expense:
        return 'Registrar Gasto';
      case TransactionType.transfer:
        return 'Realizar Transferencia';
    }
  }

  String _getSuccessMessage() {
    switch (_selectedType) {
      case TransactionType.income:
        return 'Ingreso registrado';
      case TransactionType.expense:
        return 'Gasto registrado';
      case TransactionType.transfer:
        return 'Transferencia realizada';
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.wallet:
        return Icons.account_balance_wallet;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.credit:
        return Icons.credit_card;
      case AccountType.loan:
        return Icons.real_estate_agent;
      case AccountType.receivable:
        return Icons.arrow_circle_down;
      case AccountType.payable:
        return Icons.arrow_circle_up;
    }
  }

  IconData _getCategoryIcon(String? iconName) {
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

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.primary;
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  /// Widget que se muestra cuando no hay cuentas disponibles
  Widget _buildNoAccountsMessage(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.warning.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sin cuentas disponibles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Para registrar transacciones, primero debes crear al menos una cuenta (efectivo, banco, tarjeta, etc.)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navegar a la pantalla de cuentas
                    // Usamos GoRouter si está disponible
                    try {
                      final router = GoRouter.of(context);
                      router.go('/accounts');
                    } catch (e) {
                      // Si no hay router, simplemente cerrar
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Cuenta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
