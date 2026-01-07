import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../helpers/default_account_selector.dart';
import '../providers/transaction_provider.dart';
import 'transaction_details_section.dart';

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
  final _amountFocusNode = FocusNode();

  late TransactionType _selectedType;
  String? _selectedAccountId;
  String? _selectedTransferAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Detalles adicionales de transacción
  TransactionDetails _transactionDetails = const TransactionDetails();

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
    _amountFocusNode.dispose();
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

    // Seleccionar cuenta predeterminada según tipo de transacción
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = DefaultAccountSelector.selectDefaultAccount(
        accounts: accounts,
        transactionType: _selectedType,
      );
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
                          labelText: 'Descripción',
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
                      const SizedBox(height: AppSpacing.md),

                      // Detalles adicionales (solo para gastos)
                      if (_selectedType == TransactionType.expense)
                        TransactionDetailsSection(
                          initialItemDescription: isEditing
                              ? widget.transaction?.itemDescription
                              : null,
                          initialBrand:
                              isEditing ? widget.transaction?.brand : null,
                          initialQuantity:
                              isEditing ? widget.transaction?.quantity : null,
                          initialUnitId:
                              isEditing ? widget.transaction?.unitId : null,
                          initialEstablishmentId: isEditing
                              ? widget.transaction?.establishmentId
                              : null,
                          initialPaymentMethod: isEditing
                              ? widget.transaction?.paymentMethodV2
                              : null,
                          initialPaymentMedium: isEditing
                              ? widget.transaction?.paymentMedium
                              : null,
                          initialPaymentSubmedium: isEditing
                              ? widget.transaction?.paymentSubmedium
                              : null,
                          selectedAccount: _selectedAccountId != null
                              ? accounts.cast<AccountModel?>().firstWhere(
                                    (a) => a?.id == _selectedAccountId,
                                    orElse: () => null,
                                  )
                              : null,
                          onDetailsChanged: (details) {
                            setState(() => _transactionDetails = details);
                          },
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
                  isEditing ? 'Editar Transacción' : 'Nueva Transacción',
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
                final newType = selection.first;
                final accounts = ref.read(activeAccountsProvider);
                setState(() {
                  _selectedType = newType;
                  _selectedCategoryId = null;
                  // Reseleccionar cuenta predeterminada según nuevo tipo
                  _selectedAccountId = DefaultAccountSelector.selectDefaultAccount(
                    accounts: accounts,
                    transactionType: newType,
                  );
                  // Limpiar cuenta de transferencia si ya no es transferencia
                  if (newType != TransactionType.transfer) {
                    _selectedTransferAccountId = null;
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return GestureDetector(
      onTap: () {
        // Asegurar que el campo de monto reciba foco al tocar
        _amountFocusNode.requestFocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: false,
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
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
            Text(
              'Ingresa el monto',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getTypeColor().withValues(alpha: 0.7),
                  ),
            ),
          ],
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
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem<String>(
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
          return 'Selecciona una categoría';
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

      // Calcular precio unitario si hay cantidad
      double? unitPrice;
      if (_transactionDetails.quantity != null &&
          _transactionDetails.quantity! > 0) {
        unitPrice = amount / _transactionDetails.quantity!;
      }

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
          // Campos detallados v3
          itemDescription: _transactionDetails.itemDescription,
          brand: _transactionDetails.brand,
          quantity: _transactionDetails.quantity,
          unitId: _transactionDetails.unitId,
          unitPrice: unitPrice,
          establishmentId: _transactionDetails.establishmentId,
          paymentMethodV2: _transactionDetails.paymentMethod,
          paymentMedium: _transactionDetails.paymentMedium,
          paymentSubmedium: _transactionDetails.paymentSubmedium,
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
              // Campos detallados v3
              itemDescription: _transactionDetails.itemDescription,
              brand: _transactionDetails.brand,
              quantity: _transactionDetails.quantity,
              unitId: _transactionDetails.unitId,
              establishmentId: _transactionDetails.establishmentId,
              paymentMethodV2: _transactionDetails.paymentMethod,
              paymentMedium: _transactionDetails.paymentMedium,
              paymentSubmedium: _transactionDetails.paymentSubmedium,
            );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Transacción actualizada' : _getSuccessMessage()),
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
        maxHeight: MediaQuery.of(context).size.height * 0.6,
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
          // Icono animado
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Primero, crea tu cuenta',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Solo toma 30 segundos crear tu primera cuenta y empezar a registrar tus finanzas.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Chips de tipos de cuenta
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _buildAccountTypeChip(context, 'Efectivo', Icons.payments, const Color(0xFF4CAF50)),
              _buildAccountTypeChip(context, 'Banco', Icons.account_balance, const Color(0xFF2196F3)),
              _buildAccountTypeChip(context, 'Tarjeta', Icons.credit_card, const Color(0xFFF44336)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                try {
                  GoRouter.of(context).go('/accounts');
                } catch (e) {
                  // Si no hay router, simplemente cerrar
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Crear mi primera cuenta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
