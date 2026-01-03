import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_provider.dart';

class AddAccountSheet extends ConsumerStatefulWidget {
  final AccountModel? account; // Para editar

  const AddAccountSheet({super.key, this.account});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _lastFourController = TextEditingController();

  AccountType _selectedType = AccountType.bank;
  String _selectedCurrency = 'MXN';
  String _selectedColor = '#4CAF50';
  bool _includeInTotal = true;
  bool _isLoading = false;

  bool get isEditing => widget.account != null;

  final List<String> _currencies = ['MXN', 'USD', 'EUR', 'GBP'];
  final List<String> _colors = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.abs().toString();
      _creditLimitController.text = widget.account!.creditLimit.toString();
      _bankNameController.text = widget.account!.bankName ?? '';
      _lastFourController.text = widget.account!.lastFourDigits ?? '';
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currency;
      _selectedColor = widget.account!.color ?? '#4CAF50';
      _includeInTotal = widget.account!.includeInTotal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _bankNameController.dispose();
    _lastFourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance para el icono
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de cuenta
                      Text(
                        'Tipo de Cuenta',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: AccountType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(type.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedType = type);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la cuenta',
                          prefixIcon: Icon(Icons.label_outline),
                          hintText: 'ej. Banco Principal, Efectivo...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Balance y Moneda
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _balanceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                labelText: _selectedType == AccountType.credit
                                    ? 'Saldo (deuda)'
                                    : 'Balance actual',
                                prefixIcon: const Icon(Icons.attach_money),
                                hintText: '0.00',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa el balance';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: const InputDecoration(
                                labelText: 'Moneda',
                              ),
                              items: _currencies.map((currency) {
                                return DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCurrency = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Limite de credito (solo para tarjetas)
                      if (_selectedType == AccountType.credit) ...[
                        TextFormField(
                          controller: _creditLimitController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Limite de credito',
                            prefixIcon: Icon(Icons.credit_score),
                            hintText: '0.00',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Banco y ultimos 4 digitos (para bank y credit)
                      if (_selectedType == AccountType.bank ||
                          _selectedType == AccountType.credit ||
                          _selectedType == AccountType.savings) ...[
                        TextFormField(
                          controller: _bankNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del banco (opcional)',
                            prefixIcon: Icon(Icons.business),
                            hintText: 'ej. BBVA, Santander...',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _lastFourController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Ultimos 4 digitos (opcional)',
                            prefixIcon: Icon(Icons.pin),
                            hintText: '1234',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Color
                      Text(
                        'Color',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: _colors.map((color) {
                          final isSelected = _selectedColor == color;
                          final colorValue = _parseColor(color);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorValue,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Incluir en total
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Incluir en patrimonio neto'),
                        subtitle: const Text(
                          'Sumar o restar este balance del total',
                        ),
                        value: _includeInTotal,
                        onChanged: (value) {
                          setState(() => _includeInTotal = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Boton guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isEditing ? 'Guardar Cambios' : 'Crear Cuenta'),
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      final creditLimit =
          double.tryParse(_creditLimitController.text) ?? 0.0;

      bool success;

      if (isEditing) {
        final updatedAccount = widget.account!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          currency: _selectedCurrency,
          balance: _selectedType == AccountType.credit ? -balance : balance,
          creditLimit: creditLimit,
          color: _selectedColor,
          bankName: _bankNameController.text.isEmpty
              ? null
              : _bankNameController.text.trim(),
          lastFourDigits: _lastFourController.text.isEmpty
              ? null
              : _lastFourController.text,
          includeInTotal: _includeInTotal,
          isSynced: false,
        );
        success = await ref
            .read(accountsProvider.notifier)
            .updateAccount(updatedAccount);
      } else {
        success = await ref.read(accountsProvider.notifier).createAccount(
              name: _nameController.text.trim(),
              type: _selectedType,
              currency: _selectedCurrency,
              balance: _selectedType == AccountType.credit ? -balance : balance,
              creditLimit: creditLimit,
              color: _selectedColor,
              bankName: _bankNameController.text.isEmpty
                  ? null
                  : _bankNameController.text.trim(),
              lastFourDigits: _lastFourController.text.isEmpty
                  ? null
                  : _lastFourController.text,
            );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Cuenta actualizada' : 'Cuenta creada',
            ),
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

  Color _parseColor(String colorHex) {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
