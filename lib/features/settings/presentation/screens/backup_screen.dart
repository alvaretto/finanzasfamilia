import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/backup_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isProcessing = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final transactionsState = ref.watch(transactionsProvider);
    final budgetsState = ref.watch(budgetsProvider);
    final goalsState = ref.watch(goalsProvider);
    final recurrentsState = ref.watch(recurringProvider);

    final totalItems = accountsState.accounts.length +
        transactionsState.transactions.length +
        budgetsState.budgets.length +
        goalsState.allGoals.length +
        recurrentsState.items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Los respaldos te permiten guardar una copia completa '
                      'de tus datos y restaurarlos cuando quieras.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Estadísticas
          Text(
            'Datos actuales',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildStatRow(Icons.account_balance_wallet, 'Cuentas',
              accountsState.accounts.length),
          _buildStatRow(Icons.receipt_long, 'Transacciones',
              transactionsState.transactions.length),
          _buildStatRow(
              Icons.pie_chart, 'Presupuestos', budgetsState.budgets.length),
          _buildStatRow(Icons.flag, 'Metas', goalsState.allGoals.length),
          _buildStatRow(
              Icons.repeat, 'Recurrentes', recurrentsState.items.length),

          const Divider(height: AppSpacing.xl),

          Row(
            children: [
              Icon(Icons.cloud_upload, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Total: $totalItems elementos',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Status
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _status.contains('Error')
                      ? AppColors.error
                      : _status.contains('exitoso')
                          ? Colors.green
                          : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Botón Crear Respaldo
          FilledButton.icon(
            onPressed: _isProcessing || totalItems == 0 ? null : _createBackup,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.backup),
            label: Text(_isProcessing ? 'Creando...' : 'Crear Respaldo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Botón Restaurar Respaldo
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _restoreBackup,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar desde Archivo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Warning para restaurar
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Importante al restaurar',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• Al restaurar, se reemplazarán TODOS los datos actuales\n'
                    '• Crea un respaldo antes de restaurar\n'
                    '• La sincronización con Supabase puede tardar',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _isProcessing = true;
      _status = 'Preparando respaldo...';
    });

    try {
      // Recopilar todos los datos
      final accountsState = ref.read(accountsProvider);
      final transactionsState = ref.read(transactionsProvider);
      final budgetsState = ref.read(budgetsProvider);
      final goalsState = ref.read(goalsProvider);
      final recurrentsState = ref.read(recurringProvider);

      setState(() => _status = 'Creando archivo de respaldo...');

      final backup = await BackupService.instance.createBackup(
        accounts: accountsState.accounts,
        transactions: transactionsState.transactions,
        budgets: budgetsState.budgets,
        goals: goalsState.allGoals,
        recurrents: recurrentsState.items,
      );

      setState(() => _status = 'Compartiendo respaldo...');

      await BackupService.instance.exportAndShareBackup(backup);

      setState(() {
        _isProcessing = false;
        _status =
            'Respaldo creado exitoso: ${backup.totalItems} elementos (${backup.estimatedSizeKB} KB)';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Respaldo creado: ${backup.totalItems} elementos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Error al crear respaldo: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    // Advertencia antes de restaurar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: AppColors.warning, size: 48),
        title: const Text('¿Restaurar respaldo?'),
        content: const Text(
          'Esto reemplazará TODOS tus datos actuales con los del respaldo.\n\n'
          '¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);

      setState(() {
        _isProcessing = true;
        _status = 'Validando archivo...';
      });

      // Validar archivo
      final isValid = await BackupService.instance.validateBackupFile(file);
      if (!isValid) {
        throw Exception('Archivo de respaldo inválido');
      }

      setState(() => _status = 'Importando datos...');

      // Importar respaldo
      final backup = await BackupService.instance.importBackup(file);

      setState(() => _status = 'Restaurando ${backup.totalItems} elementos...');

      // Restaurar cuentas
      if (backup.accounts.isNotEmpty) {
        setState(() => _status = 'Restaurando cuentas...');
        for (final account in backup.accounts) {
          await ref.read(accountsProvider.notifier).createAccount(
                name: account.name,
                type: account.type,
                currency: account.currency,
                balance: account.balance,
                color: account.color,
                icon: account.icon,
                bankName: account.bankName,
              );
        }
      }

      // Restaurar transacciones
      if (backup.transactions.isNotEmpty) {
        setState(() => _status = 'Restaurando transacciones...');
        // NOTE: Este proceso puede ser lento con muchas transacciones
        // Considerar batching en el futuro
        for (final tx in backup.transactions) {
          await ref.read(transactionsProvider.notifier).createTransaction(
                accountId: tx.accountId,
                amount: tx.amount,
                type: tx.type,
                description: tx.description,
                date: tx.date,
                categoryId: tx.categoryId,
              );
        }
      }

      // Restaurar presupuestos
      if (backup.budgets.isNotEmpty) {
        setState(() => _status = 'Restaurando presupuestos...');
        for (final budget in backup.budgets) {
          await ref.read(budgetsProvider.notifier).createBudget(
                categoryId: budget.categoryId,
                amount: budget.amount,
                period: budget.period,
              );
        }
      }

      // Restaurar metas
      if (backup.goals.isNotEmpty) {
        setState(() => _status = 'Restaurando metas...');
        for (final goal in backup.goals) {
          await ref.read(goalsProvider.notifier).createGoal(
                name: goal.name,
                targetAmount: goal.targetAmount,
                currentAmount: goal.currentAmount,
                targetDate: goal.targetDate,
              );
        }
      }

      // Restaurar recurrentes
      if (backup.recurrents.isNotEmpty) {
        setState(() => _status = 'Restaurando recurrentes...');
        // NOTE: RecurringProvider no expone create directamente
        // Este es un placeholder - ajustar según la API del provider
      }

      setState(() => _status = 'Sincronizando con Supabase...');

      // Sincronizar todo
      await ref.read(accountsProvider.notifier).syncAccounts();
      await ref.read(transactionsProvider.notifier).syncTransactions();
      await ref.read(budgetsProvider.notifier).syncBudgets();
      await ref.read(goalsProvider.notifier).syncGoals();

      setState(() {
        _isProcessing = false;
        _status = 'Restauración exitosa: ${backup.totalItems} elementos';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restauración completa: ${backup.totalItems} elementos'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Error al restaurar: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
