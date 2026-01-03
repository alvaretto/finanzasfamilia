import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../domain/models/budget_model.dart';
import '../providers/budget_provider.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  final BudgetModel? budget;

  const AddBudgetSheet({super.key, this.budget});

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  CategoryModel? _selectedCategory;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  bool _isLoading = false;

  bool get isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _amountController.text = widget.budget!.amount.toStringAsFixed(0);
      _selectedPeriod = widget.budget!.period;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetsProvider);
    final availableCategories = state.categoriesWithoutBudget;

    // Si estamos editando, incluir la categoria actual
    final categories = isEditing
        ? state.expenseCategories
        : availableCategories;

    // Seleccionar categoria del presupuesto si estamos editando
    if (isEditing && _selectedCategory == null) {
      _selectedCategory = state.expenseCategories
          .where((c) => c.id == widget.budget!.categoryId)
          .firstOrNull;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_chart,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar Presupuesto' : 'Nuevo Presupuesto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Categoria
              DropdownButtonFormField<CategoryModel>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _parseColor(cat.color)?.withValues(alpha: 0.1) ??
                                Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            _getIconData(cat.icon),
                            size: 16,
                            color: _parseColor(cat.color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: isEditing ? null : (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) return 'Selecciona una categoría';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Monto
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto del presupuesto',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Periodo
              Text(
                'Periodo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<BudgetPeriod>(
                segments: BudgetPeriod.values.map((period) {
                  return ButtonSegment(
                    value: period,
                    label: Text(period.displayName),
                  );
                }).toList(),
                selected: {_selectedPeriod},
                onSelectionChanged: (selection) {
                  setState(() => _selectedPeriod = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Recibirás alertas cuando llegues al 80% del presupuesto',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Botón guardar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Guardar cambios' : 'Crear presupuesto'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final notifier = ref.read(budgetsProvider.notifier);

    bool success;
    if (isEditing) {
      final updated = widget.budget!.copyWith(
        amount: amount,
        period: _selectedPeriod,
      );
      success = await notifier.updateBudget(updated);
    } else {
      success = await notifier.createBudget(
        categoryId: _selectedCategory!.id,
        amount: amount,
        period: _selectedPeriod,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Presupuesto actualizado' : 'Presupuesto creado'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = ref.read(budgetsProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Error al guardar'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (_) {
      return null;
    }
  }

  IconData _getIconData(String? iconName) {
    const icons = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'power': Icons.power,
      'favorite': Icons.favorite,
      'movie': Icons.movie,
      'shopping_bag': Icons.shopping_bag,
      'school': Icons.school,
      'more_horiz': Icons.more_horiz,
    };
    return icons[iconName] ?? Icons.category;
  }
}
