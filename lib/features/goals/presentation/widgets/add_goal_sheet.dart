import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/goal_model.dart';
import '../providers/goal_provider.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  final GoalModel? goal;

  const AddGoalSheet({super.key, this.goal});

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();

  DateTime? _targetDate;
  String _selectedIcon = 'savings';
  String _selectedColor = '#6366F1';
  bool _isLoading = false;

  bool get isEditing => widget.goal != null;

  static const _icons = {
    'savings': Icons.savings,
    'beach_access': Icons.beach_access,
    'home': Icons.home,
    'directions_car': Icons.directions_car,
    'laptop': Icons.laptop,
    'school': Icons.school,
    'flight': Icons.flight,
    'shopping_bag': Icons.shopping_bag,
    'health_and_safety': Icons.health_and_safety,
    'child_friendly': Icons.child_friendly,
    'shield': Icons.shield,
  };

  static const _colors = [
    '#6366F1', // Indigo
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#84CC16', // Lime
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.goal!.name;
      _targetController.text = widget.goal!.targetAmount.toStringAsFixed(0);
      _currentController.text = widget.goal!.currentAmount.toStringAsFixed(0);
      _targetDate = widget.goal!.targetDate;
      _selectedIcon = widget.goal!.icon ?? 'savings';
      _selectedColor = widget.goal!.color ?? '#6366F1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.savings,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar Meta' : 'Nueva Meta',
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

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    prefixIcon: Icon(Icons.flag),
                    hintText: 'Ej: Vacaciones 2026',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Monto objetivo
                TextFormField(
                  controller: _targetController,
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el monto objetivo';
                    }
                    final amount = double.tryParse(value.replaceAll(',', ''));
                    if (amount == null || amount <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Monto inicial (solo al crear)
                if (!isEditing)
                  TextFormField(
                    controller: _currentController,
                    decoration: const InputDecoration(
                      labelText: 'Ahorro inicial (opcional)',
                      prefixIcon: Icon(Icons.savings_outlined),
                      prefixText: '\$ ',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (!isEditing) const SizedBox(height: AppSpacing.md),

                // Fecha objetivo
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha objetivo (opcional)',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _targetDate != null
                              ? dateFormat.format(_targetDate!)
                              : 'Sin fecha límite',
                          style: TextStyle(
                            color: _targetDate != null
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        if (_targetDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _targetDate = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Icono
                Text(
                  'Icono',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _icons.entries.map((entry) {
                    final isSelected = _selectedIcon == entry.key;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = entry.key),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _parseColor(_selectedColor)?.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected
                                ? _parseColor(_selectedColor) ?? AppColors.primary
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          color: isSelected
                              ? _parseColor(_selectedColor)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Color
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _colors.map((colorHex) {
                    final color = _parseColor(colorHex)!;
                    final isSelected = _selectedColor == colorHex;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

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
                        : Text(isEditing ? 'Guardar cambios' : 'Crear meta'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final targetAmount = double.parse(_targetController.text.replaceAll(',', ''));
    final currentAmount = _currentController.text.isEmpty
        ? 0.0
        : double.parse(_currentController.text.replaceAll(',', ''));

    final notifier = ref.read(goalsProvider.notifier);

    bool success;
    if (isEditing) {
      final updated = widget.goal!.copyWith(
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        targetDate: _targetDate,
        icon: _selectedIcon,
        color: _selectedColor,
      );
      success = await notifier.updateGoal(updated);
    } else {
      success = await notifier.createGoal(
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _targetDate,
        icon: _selectedIcon,
        color: _selectedColor,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Meta actualizada' : 'Meta creada'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = ref.read(goalsProvider).errorMessage;
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
}
