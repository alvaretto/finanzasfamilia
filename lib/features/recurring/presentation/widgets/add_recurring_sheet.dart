import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/models/recurring_model.dart';
import '../providers/recurring_provider.dart';

class AddRecurringSheet extends ConsumerStatefulWidget {
  final RecurringModel? recurring;

  const AddRecurringSheet({super.key, this.recurring});

  @override
  ConsumerState<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  RecurringType _type = RecurringType.expense;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  String? _accountId;
  String? _categoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  bool get isEditing => widget.recurring != null;

  @override
  void initState() {
    super.initState();
    if (widget.recurring != null) {
      final r = widget.recurring!;
      _amountController.text = r.amount.toStringAsFixed(0);
      _descriptionController.text = r.description ?? '';
      _type = r.type;
      _frequency = r.frequency;
      _accountId = r.accountId;
      _categoryId = r.categoryId;
      _startDate = r.startDate;
      _endDate = r.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = ref.read(authProvider).user!.id;
    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    final recurring = RecurringModel(
      id: widget.recurring?.id ?? const Uuid().v4(),
      userId: userId,
      accountId: _accountId!,
      categoryId: _categoryId,
      amount: amount,
      type: _type,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      frequency: _frequency,
      startDate: _startDate,
      endDate: _endDate,
      nextOccurrence: widget.recurring?.nextOccurrence ?? _startDate,
      isActive: widget.recurring?.isActive ?? true,
      createdAt: widget.recurring?.createdAt ?? DateTime.now(),
    );

    final success = isEditing
        ? await ref.read(recurringProvider.notifier).update(recurring)
        : await ref.read(recurringProvider.notifier).create(recurring);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(activeAccountsProvider);
    final categories = ref.watch(categoriesProvider);
    final filteredCategories =
        categories.where((c) => c.type == _type.name).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Título
              Text(
                isEditing ? 'Editar Recurrente' : 'Nueva Recurrente',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tipo (Ingreso/Gasto)
              SegmentedButton<RecurringType>(
                segments: RecurringType.values.map((t) {
                  return ButtonSegment(
                    value: t,
                    label: Text(t.displayName),
                    icon: Icon(
                      t == RecurringType.income
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                  );
                }).toList(),
                selected: {_type},
                onSelectionChanged: (selected) {
                  setState(() {
                    _type = selected.first;
                    _categoryId = null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Monto
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: _type == RecurringType.income
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un monto';
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Renta, Netflix, Sueldo...',
                  prefixIcon: Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),

              // Cuenta
              DropdownButtonFormField<String>(
                value: _accountId,
                decoration: const InputDecoration(
                  labelText: 'Cuenta',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: accounts.map((a) {
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _accountId = value),
                validator: (value) =>
                    value == null ? 'Selecciona una cuenta' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Categoría
              DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoría (opcional)',
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ...filteredCategories.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: AppSpacing.md),

              // Frecuencia
              DropdownButtonFormField<RecurringFrequency>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: RecurringFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Fechas
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Fecha inicio',
                      date: _startDate,
                      onChanged: (date) {
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateField(
                      label: 'Fecha fin (opcional)',
                      date: _endDate,
                      allowClear: true,
                      onChanged: (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Botón
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Guardar' : 'Crear'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool allowClear;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.date,
    this.allowClear = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: allowClear && date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null ? dateFormat.format(date!) : 'Sin fecha',
          style: TextStyle(
            color: date != null
                ? null
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
