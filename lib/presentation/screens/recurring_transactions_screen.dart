import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/recurring_transactions_provider.dart';
import '../../domain/services/recurring_transaction_service.dart';

/// Pantalla de transacciones recurrentes
class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(activeRecurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos Recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (items) => items.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context, ref))
            : _RecurringList(items: items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(activeRecurringTransactionsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _RecurringFormSheet(),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pagos Recurrentes'),
        content: const Text(
          'Configura pagos que se repiten automáticamente:\n\n'
          '• Servicios públicos (EDEQ, EPA, EfiGas)\n'
          '• Suscripciones (Netflix, Spotify)\n'
          '• Pagos de préstamos\n'
          '• Arriendo mensual\n\n'
          'La app te recordará cuando sea hora de pagar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

/// Estado de error
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin pagos recurrentes',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Configura tus pagos mensuales como servicios públicos o suscripciones.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar pago recurrente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de transacciones recurrentes
class _RecurringList extends ConsumerWidget {
  final List<RecurringTransactionData> items;

  const _RecurringList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) => _RecurringTile(item: items[index]),
    );
  }
}

/// Tile de transacción recurrente
class _RecurringTile extends ConsumerWidget {
  final RecurringTransactionData item;

  const _RecurringTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpense = item.type == 'expense';
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('d MMM', 'es');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.1),
          child: Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getFrequencyText(item.frequency),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Próximo: ${item.nextExecutionDate != null ? dateFormat.format(item.nextExecutionDate!) : 'Sin fecha'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(item.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!item.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactivo',
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
        onTap: () => _showOptions(context, ref),
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quincenal';
      case 'monthly':
        return 'Mensual';
      case 'bimonthly':
        return 'Bimestral';
      case 'quarterly':
        return 'Trimestral';
      case 'semiannual':
        return 'Semestral';
      case 'yearly':
        return 'Anual';
      default:
        return frequency;
    }
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _RecurringFormSheet(existingItem: item),
                );
              },
            ),
            ListTile(
              leading: Icon(
                item.isActive ? Icons.pause : Icons.play_arrow,
              ),
              title: Text(item.isActive ? 'Pausar' : 'Activar'),
              onTap: () async {
                Navigator.pop(context);
                final notifier =
                    ref.read(recurringTransactionsNotifierProvider.notifier);
                if (item.isActive) {
                  await notifier.deactivate(item.id);
                } else {
                  await notifier.activate(item.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar pago recurrente'),
                    content: Text(
                        '¿Eliminar "${item.name}"? Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(recurringTransactionsNotifierProvider.notifier)
                      .delete(item.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario para crear/editar transacción recurrente
class _RecurringFormSheet extends ConsumerStatefulWidget {
  final RecurringTransactionData? existingItem;

  const _RecurringFormSheet({this.existingItem});

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  int _dayOfExecution = 1;
  final DateTime _startDate = DateTime.now();
  bool _requiresConfirmation = false;
  bool _isLoading = false;

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _amountController.text = item.amount.toStringAsFixed(0);
      _descriptionController.text = item.description ?? '';
      _type = item.type;
      _frequency = RecurrenceFrequency.values.firstWhere(
        (e) => e.name == item.frequency,
        orElse: () => RecurrenceFrequency.monthly,
      );
      _dayOfExecution = item.dayOfExecution;
      _requiresConfirmation = item.requiresConfirmation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'Editar Pago Recurrente' : 'Nuevo Pago Recurrente',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tipo
                Text('Tipo', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Gasto'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Ingreso'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) =>
                      setState(() => _type = value.first),
                ),
                const SizedBox(height: 16),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: EDEQ - Energía',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 16),

                // Monto
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa el monto';
                    if (double.tryParse(v) == null) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Frecuencia
                Text('Frecuencia', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: RecurrenceFrequency.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(_getFrequencyLabel(f)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                const SizedBox(height: 16),

                // Día de ejecución
                Text('Día de ejecución', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Slider(
                  value: _dayOfExecution.toDouble(),
                  min: 1,
                  max: _frequency == RecurrenceFrequency.weekly ? 7 : 28,
                  divisions:
                      (_frequency == RecurrenceFrequency.weekly ? 6 : 27),
                  label: _frequency == RecurrenceFrequency.weekly
                      ? _getDayOfWeekLabel(_dayOfExecution)
                      : 'Día $_dayOfExecution',
                  onChanged: (v) =>
                      setState(() => _dayOfExecution = v.round()),
                ),
                Center(
                  child: Text(
                    _frequency == RecurrenceFrequency.weekly
                        ? _getDayOfWeekLabel(_dayOfExecution)
                        : 'Día $_dayOfExecution del mes',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Requiere confirmación
                SwitchListTile(
                  title: const Text('Requiere confirmación'),
                  subtitle: const Text(
                    'Te preguntará antes de registrar el pago',
                  ),
                  value: _requiresConfirmation,
                  onChanged: (v) =>
                      setState(() => _requiresConfirmation = v),
                ),
                const SizedBox(height: 24),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFrequencyLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Diario';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.biweekly:
        return 'Quincenal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.bimonthly:
        return 'Bimestral';
      case RecurrenceFrequency.quarterly:
        return 'Trimestral';
      case RecurrenceFrequency.semiannual:
        return 'Semestral';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  String _getDayOfWeekLabel(int day) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return days[day - 1];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(recurringTransactionsNotifierProvider.notifier);

      if (isEditing) {
        // Actualizar existente
        await notifier.updateRecurring(
          id: widget.existingItem!.id,
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          frequency: _frequency,
          dayOfExecution: _dayOfExecution,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          requiresConfirmation: _requiresConfirmation,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago recurrente actualizado')),
          );
        }
      } else {
        // Crear nuevo - usar categoría por defecto
        const defaultCategoryId = 'cat-gastos-servicios';

        await notifier.create(
          name: _nameController.text.trim(),
          type: _type,
          amount: double.parse(_amountController.text),
          categoryId: defaultCategoryId,
          frequency: _frequency,
          dayOfExecution: _dayOfExecution,
          startDate: _startDate,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          requiresConfirmation: _requiresConfirmation,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago recurrente creado')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
