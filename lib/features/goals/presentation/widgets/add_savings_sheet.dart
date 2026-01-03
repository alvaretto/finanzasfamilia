import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/goal_model.dart';
import '../providers/goal_provider.dart';

class AddSavingsSheet extends ConsumerStatefulWidget {
  final GoalModel goal;

  const AddSavingsSheet({super.key, required this.goal});

  @override
  ConsumerState<AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends ConsumerState<AddSavingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isWithdraw = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final color = _parseColor(widget.goal.color) ?? AppColors.primary;

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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      _isWithdraw ? Icons.remove : Icons.add,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.goal.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Ahorrado: ${currencyFormat.format(widget.goal.currentAmount)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tipo de operación
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.add),
                    label: Text('Agregar'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.remove),
                    label: Text('Retirar'),
                  ),
                ],
                selected: {_isWithdraw},
                onSelectionChanged: (selection) {
                  setState(() => _isWithdraw = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Monto
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: _isWithdraw ? 'Monto a retirar' : 'Monto a agregar',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }
                  if (_isWithdraw && amount > widget.goal.currentAmount) {
                    return 'No puedes retirar más de lo ahorrado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Botones de monto rápido
              if (!_isWithdraw) ...[
                Text(
                  'Montos sugeridos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [100, 500, 1000, 5000].map((amount) {
                    return ActionChip(
                      label: Text('\$$amount'),
                      onPressed: () {
                        _amountController.text = amount.toString();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Info de progreso
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meta:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          currencyFormat.format(widget.goal.targetAmount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso actual:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${widget.goal.percentComplete.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Restante:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          currencyFormat.format(widget.goal.remaining),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isWithdraw ? AppColors.warning : color,
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
                      : Text(_isWithdraw ? 'Retirar' : 'Agregar ahorro'),
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
    final notifier = ref.read(goalsProvider.notifier);

    bool success;
    if (_isWithdraw) {
      success = await notifier.withdrawSavings(widget.goal.id, amount);
    } else {
      success = await notifier.addSavings(widget.goal.id, amount);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);

        // Verificar si se completó la meta
        final updatedGoal = ref.read(goalsProvider.notifier).getById(widget.goal.id);
        if (updatedGoal?.isCompleted == true && !widget.goal.isCompleted) {
          _showCompletionCelebration(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isWithdraw ? 'Retiro realizado' : 'Ahorro agregado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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

  void _showCompletionCelebration(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events,
          size: 64,
          color: AppColors.warning,
        ),
        title: const Text('¡Felicidades!'),
        content: Text('Has completado tu meta "${widget.goal.name}"'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Genial!'),
          ),
        ],
      ),
    );
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
