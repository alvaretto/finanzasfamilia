import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/savings_goals_provider.dart';
import '../../domain/repositories/savings_goal_repository.dart';

/// Mapa de códigos de iconos a IconData constantes para tree-shaking
const Map<int, IconData> _iconMap = {
  0xe57f: Icons.savings,
  0xe1bc: Icons.home,
  0xef4e: Icons.flight,
  0xe531: Icons.phone_iphone,
  0xe558: Icons.directions_car,
  0xe7f1: Icons.school,
  0xe548: Icons.laptop,
  0xe53b: Icons.beach_access,
  0xe1b1: Icons.fitness_center,
  0xea12: Icons.celebration,
};

/// Obtiene el IconData constante para un código de icono
IconData getIconFromCode(int code) => _iconMap[code] ?? Icons.savings;

/// Pantalla de gestión de metas de ahorro
class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas de Ahorro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(savingsGoalsNotifierProvider),
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) => goals.isEmpty
            ? const _EmptyState()
            : _GoalsList(goals: goals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(savingsGoalsNotifierProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Meta'),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _GoalFormSheet(),
    );
  }
}

/// Estado vacío - Sin metas
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            '¡Empieza a ahorrar!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera meta de ahorro\ny alcanza tus sueños',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Ver ideas de metas'),
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

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Lista de metas de ahorro
class _GoalsList extends StatelessWidget {
  final List<SavingsGoalData> goals;

  const _GoalsList({required this.goals});

  @override
  Widget build(BuildContext context) {
    // Separar por estado
    final inProgress = goals.where((g) => g.status == SavingsGoalStatus.inProgress).toList();
    final completed = goals.where((g) => g.status == SavingsGoalStatus.completed).toList();
    final paused = goals.where((g) => g.status == SavingsGoalStatus.paused).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen
        _GoalsSummary(goals: goals),
        const SizedBox(height: 24),

        // Metas en progreso
        if (inProgress.isNotEmpty) ...[
          _SectionHeader(
            title: 'En Progreso',
            count: inProgress.length,
            color: Colors.blue,
          ),
          ...inProgress.map((g) => _GoalCard(goal: g)),
          const SizedBox(height: 16),
        ],

        // Metas completadas
        if (completed.isNotEmpty) ...[
          _SectionHeader(
            title: 'Completadas',
            count: completed.length,
            color: Colors.green,
          ),
          ...completed.map((g) => _GoalCard(goal: g)),
          const SizedBox(height: 16),
        ],

        // Metas pausadas
        if (paused.isNotEmpty) ...[
          _SectionHeader(
            title: 'Pausadas',
            count: paused.length,
            color: Colors.grey,
          ),
          ...paused.map((g) => _GoalCard(goal: g)),
        ],
      ],
    );
  }
}

/// Encabezado de sección
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen de metas
class _GoalsSummary extends StatelessWidget {
  final List<SavingsGoalData> goals;

  const _GoalsSummary({required this.goals});

  @override
  Widget build(BuildContext context) {
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalCurrent = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final overallProgress = totalTarget > 0 ? (totalCurrent / totalTarget) * 100 : 0.0;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.savings,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progreso Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(totalCurrent)} de ${currencyFormat.format(totalTarget)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${overallProgress.toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '${goals.length} metas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (overallProgress / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de meta individual
class _GoalCard extends ConsumerWidget {
  final SavingsGoalData goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final statusColor = _getStatusColor(goal.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showGoalDetails(context, ref, goal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Icono con color
                  CircleAvatar(
                    backgroundColor: Color(goal.color).withValues(alpha: 0.2),
                    child: Icon(
                      getIconFromCode(goal.icon),
                      color: Color(goal.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Información de la meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _StatusChip(status: goal.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currencyFormat.format(goal.currentAmount)} de ${currencyFormat.format(goal.targetAmount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (goal.targetDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            goal.daysRemaining != null && goal.daysRemaining! > 0
                                ? '${goal.daysRemaining} días restantes'
                                : goal.targetDate != null
                                    ? DateFormat('dd MMM yyyy', 'es').format(goal.targetDate!)
                                    : '',
                            style: TextStyle(
                              fontSize: 11,
                              color: goal.status == SavingsGoalStatus.overdue ? Colors.red : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Porcentaje
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${goal.progressPercentage.clamp(0, 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        currencyFormat.format(goal.remainingAmount),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (goal.progressPercentage.clamp(0, 100) / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SavingsGoalStatus status) {
    switch (status) {
      case SavingsGoalStatus.inProgress:
        return Colors.blue;
      case SavingsGoalStatus.completed:
        return Colors.green;
      case SavingsGoalStatus.overdue:
        return Colors.orange;
      case SavingsGoalStatus.paused:
        return Colors.grey;
    }
  }

  void _showGoalDetails(BuildContext context, WidgetRef ref, SavingsGoalData goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GoalDetailSheet(goal: goal),
    );
  }
}

/// Chip de estado
class _StatusChip extends StatelessWidget {
  final SavingsGoalStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SavingsGoalStatus.inProgress => ('En progreso', Colors.blue),
      SavingsGoalStatus.completed => ('Completada', Colors.green),
      SavingsGoalStatus.overdue => ('Vencida', Colors.orange),
      SavingsGoalStatus.paused => ('Pausada', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Hoja de detalle de meta
class _GoalDetailSheet extends ConsumerWidget {
  final SavingsGoalData goal;

  const _GoalDetailSheet({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Encabezado
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(goal.color).withValues(alpha: 0.2),
                      child: Icon(
                        getIconFromCode(goal.icon),
                        color: Color(goal.color),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (goal.description != null)
                            Text(
                              goal.description!,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    _StatusChip(status: goal.status),
                  ],
                ),

                const SizedBox(height: 24),

                // Progreso visual grande
                _LargeProgressIndicator(goal: goal),

                const SizedBox(height: 24),

                // Detalles
                _DetailRow(
                  icon: Icons.flag,
                  label: 'Meta',
                  value: currencyFormat.format(goal.targetAmount),
                ),
                _DetailRow(
                  icon: Icons.savings,
                  label: 'Ahorrado',
                  value: currencyFormat.format(goal.currentAmount),
                  valueColor: Colors.green,
                ),
                _DetailRow(
                  icon: Icons.trending_up,
                  label: 'Faltante',
                  value: currencyFormat.format(goal.remainingAmount),
                  valueColor: goal.remainingAmount > 0 ? Colors.orange : Colors.green,
                ),
                if (goal.targetDate != null)
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha límite',
                    value: DateFormat('dd MMM yyyy', 'es').format(goal.targetDate!),
                    valueColor: goal.status == SavingsGoalStatus.overdue ? Colors.red : null,
                  ),
                if (goal.dailySavingsNeeded != null)
                  _DetailRow(
                    icon: Icons.today,
                    label: 'Ahorro diario sugerido',
                    value: currencyFormat.format(goal.dailySavingsNeeded),
                  ),

                const SizedBox(height: 24),

                // Botón de contribuir
                if (!goal.isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showContributionDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Contribución'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Acciones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditGoalDialog(context, ref),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _togglePause(context, ref),
                        icon: Icon(goal.isActive ? Icons.pause : Icons.play_arrow),
                        label: Text(goal.isActive ? 'Pausar' : 'Reanudar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContributionDialog(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _ContributionDialog(goalId: goal.id),
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _GoalFormSheet(goalToEdit: goal),
    );
  }

  Future<void> _togglePause(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(savingsGoalsNotifierProvider.notifier);

    if (goal.isActive) {
      await notifier.pause(goal.id);
    } else {
      await notifier.resume(goal.id);
    }

    if (context.mounted) {
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(goal.isActive ? 'Meta pausada' : 'Meta reanudada'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text(
          '¿Estás seguro de eliminar la meta "${goal.name}"?\n\n'
          'Se eliminarán también todas las contribuciones asociadas.',
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

    if (confirmed == true && context.mounted) {
      await ref.read(savingsGoalsNotifierProvider.notifier).delete(goal.id);
      if (context.mounted) {
        Navigator.pop(context);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// Indicador de progreso grande
class _LargeProgressIndicator extends StatelessWidget {
  final SavingsGoalData goal;

  const _LargeProgressIndicator({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercentage.clamp(0, 100) / 100;

    return Center(
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  goal.currentAmount >= goal.targetAmount ? Colors.green : Color(goal.color),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${goal.progressPercentage.clamp(0, 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (goal.currentAmount >= goal.targetAmount)
                  const Text(
                    '¡Meta alcanzada!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de detalle
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de contribución
class _ContributionDialog extends ConsumerStatefulWidget {
  final String goalId;

  const _ContributionDialog({required this.goalId});

  @override
  ConsumerState<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends ConsumerState<_ContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Contribución'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveContribution,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveContribution() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final note = _noteController.text.isNotEmpty ? _noteController.text : null;

    try {
      await ref.read(savingsGoalsNotifierProvider.notifier).addContribution(
        goalId: widget.goalId,
        amount: amount,
        note: note,
      );

      if (mounted) {
        Navigator.pop(context);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contribución agregada'),
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
}

/// Formulario de meta (crear/editar)
class _GoalFormSheet extends ConsumerStatefulWidget {
  final SavingsGoalData? goalToEdit;

  const _GoalFormSheet({this.goalToEdit});

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime? _targetDate;
  int _selectedColor = 0xFF4CAF50;
  int _selectedIcon = 0xe57f;
  bool _isLoading = false;

  final List<int> _colors = [
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFF795548, // Brown
  ];

  final List<int> _icons = [
    0xe57f, // savings
    0xe1bc, // home
    0xef4e, // flight
    0xe531, // phone_iphone
    0xe558, // directions_car
    0xe7f1, // school
    0xe548, // laptop
    0xe53b, // beach_access
    0xe1b1, // fitness_center
    0xea12, // celebration
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _nameController.text = widget.goalToEdit!.name;
      _descriptionController.text = widget.goalToEdit!.description ?? '';
      _targetAmountController.text = widget.goalToEdit!.targetAmount.toInt().toString();
      _targetDate = widget.goalToEdit!.targetDate;
      _selectedColor = widget.goalToEdit!.color;
      _selectedIcon = widget.goalToEdit!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Text(
                isEditing ? 'Editar Meta' : 'Nueva Meta de Ahorro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la meta',
                  hintText: 'Ej: Vacaciones, iPhone, Fondo de emergencia',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Monto objetivo
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha límite
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _targetDate != null
                      ? DateFormat('dd MMM yyyy', 'es').format(_targetDate!)
                      : 'Sin fecha límite',
                ),
                subtitle: const Text('Fecha objetivo (opcional)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_targetDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _targetDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: _selectDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Color
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Icono
              Text(
                'Icono',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((iconCode) {
                  final isSelected = iconCode == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconCode),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Color(_selectedColor), width: 2)
                            : null,
                      ),
                      child: Icon(
                        getIconFromCode(iconCode),
                        color: isSelected ? Color(_selectedColor) : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveGoal,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Guardar Cambios' : 'Crear Meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: const Locale('es', 'CO'),
    );

    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final targetAmount = double.parse(_targetAmountController.text);

    try {
      final notifier = ref.read(savingsGoalsNotifierProvider.notifier);

      if (widget.goalToEdit != null) {
        await notifier.updateGoal(
          id: widget.goalToEdit!.id,
          name: name,
          description: description.isNotEmpty ? description : null,
          targetAmount: targetAmount,
          targetDate: _targetDate,
          color: _selectedColor,
          icon: _selectedIcon,
        );
      } else {
        await notifier.create(
          name: name,
          description: description.isNotEmpty ? description : null,
          targetAmount: targetAmount,
          targetDate: _targetDate,
          color: _selectedColor,
          icon: _selectedIcon,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.goalToEdit != null
                ? 'Meta actualizada'
                : 'Meta creada exitosamente'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
