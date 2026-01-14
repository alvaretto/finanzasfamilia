import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/bank_notification_provider.dart';
import '../../domain/entities/notifications/bank_notification.dart';

/// Pantalla para gestionar notificaciones bancarias
class BankNotificationsScreen extends ConsumerWidget {
  const BankNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final pendingAsync = ref.watch(pendingBankTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones Bancarias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: permissionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (hasPermission) {
          if (!Platform.isAndroid) {
            return const _UnsupportedPlatform();
          }

          if (!hasPermission) {
            return _PermissionRequest(
              onRequest: () async {
                await ref
                    .read(pendingBankTransactionsProvider.notifier)
                    .requestPermission();
                ref.invalidate(notificationPermissionProvider);
              },
            );
          }

          return pendingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (pending) {
              if (pending.isEmpty) {
                return const _EmptyState();
              }
              return _PendingTransactionsList(transactions: pending);
            },
          );
        },
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo funciona'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Activa el permiso de notificaciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Esto permite que la app lea las notificaciones de tus apps bancarias.',
              ),
              SizedBox(height: 16),
              Text(
                '2. Recibe notificaciones de tu banco',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Cuando hagas una compra, retiro o transferencia, tu banco enviará una notificación.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Confirma las transacciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Revisa y confirma cada transacción detectada para agregarla a tus finanzas.',
              ),
              SizedBox(height: 16),
              Text(
                'Bancos soportados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Bancolombia'),
              Text('• Nequi'),
              Text('• DaviPlata'),
              Text('• Davivienda'),
            ],
          ),
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

/// Widget cuando la plataforma no es Android
class _UnsupportedPlatform extends StatelessWidget {
  const _UnsupportedPlatform();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Solo disponible en Android',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'La lectura de notificaciones bancarias solo está disponible en dispositivos Android.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para solicitar permiso
class _PermissionRequest extends StatelessWidget {
  final VoidCallback onRequest;

  const _PermissionRequest({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Permiso de Notificaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Para detectar automáticamente tus transacciones bancarias, necesitamos acceso a las notificaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Solo leemos notificaciones de apps bancarias conocidas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.settings),
              label: const Text('Activar Permiso'),
            ),
            const SizedBox(height: 12),
            Text(
              'Se abrirá la configuración del sistema',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget cuando no hay transacciones pendientes
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin transacciones pendientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Las notificaciones de tus bancos aparecerán aquí automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Escuchando notificaciones...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de transacciones pendientes
class _PendingTransactionsList extends ConsumerWidget {
  final List<PendingBankTransaction> transactions;

  const _PendingTransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _PendingTransactionCard(
          transaction: transactions[index],
          onConfirm: () => _showConfirmDialog(context, ref, transactions[index]),
          onIgnore: () => _ignoreTransaction(ref, transactions[index]),
        );
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    PendingBankTransaction transaction,
  ) {
    // Por ahora solo confirmamos con valores por defecto
    // TODO: Mostrar selector de categoría y cuenta
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Transacción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monto: \$${NumberFormat('#,###').format(transaction.parsed.amount)}'),
            if (transaction.parsed.merchant != null)
              Text('Comercio: ${transaction.parsed.merchant}'),
            Text('Banco: ${transaction.parsed.bank.displayName}'),
            const SizedBox(height: 16),
            const Text(
              'Esta transacción se agregará a tus finanzas.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Seleccionar categoría y cuenta reales
              ref.read(pendingBankTransactionsProvider.notifier).confirm(
                    transaction.parsed.notificationId,
                    categoryId: 'default',
                    accountId: 'default',
                  );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _ignoreTransaction(WidgetRef ref, PendingBankTransaction transaction) {
    ref.read(pendingBankTransactionsProvider.notifier).ignore(
          transaction.parsed.notificationId,
        );
  }
}

/// Card para una transacción pendiente
class _PendingTransactionCard extends StatelessWidget {
  final PendingBankTransaction transaction;
  final VoidCallback onConfirm;
  final VoidCallback onIgnore;

  const _PendingTransactionCard({
    required this.transaction,
    required this.onConfirm,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parsed = transaction.parsed;

    final isExpense = parsed.type == NotificationTransactionType.expense;
    final isIncome = parsed.type == NotificationTransactionType.income;

    final amountColor = isExpense
        ? Colors.red
        : isIncome
            ? Colors.green
            : colorScheme.onSurface;

    final typeIcon = isExpense
        ? Icons.arrow_upward
        : isIncome
            ? Icons.arrow_downward
            : Icons.swap_horiz;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: amountColor.withValues(alpha: 0.1),
                  child: Icon(typeIcon, color: amountColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parsed.merchant ?? _getTypeLabel(parsed.type),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        parsed.bank.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}\$${NumberFormat('#,###').format(parsed.amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(parsed.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
                if (parsed.accountLastDigits != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.credit_card,
                    size: 14,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*${parsed.accountLastDigits}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onIgnore,
                  child: const Text('Ignorar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationTransactionType type) {
    switch (type) {
      case NotificationTransactionType.expense:
        return 'Gasto';
      case NotificationTransactionType.income:
        return 'Ingreso';
      case NotificationTransactionType.transfer:
        return 'Transferencia';
      case NotificationTransactionType.unknown:
        return 'Transacción';
    }
  }
}
