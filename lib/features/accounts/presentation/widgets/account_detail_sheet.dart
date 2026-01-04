import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_provider.dart';
import 'add_account_sheet.dart';

class AccountDetailSheet extends ConsumerWidget {
  final AccountModel account;

  const AccountDetailSheet({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final color = _parseColor(account.color);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con color
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _getAccountIcon(account.type),
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            account.type.displayName,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (!account.isSynced)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sin sincronizar',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warning,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Balance grande
                Text(
                  currencyFormat.format(account.balance.abs()),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: account.type == AccountType.credit
                            ? AppColors.expense
                            : color,
                      ),
                ),
                if (account.type == AccountType.credit &&
                    account.creditLimit > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Disponible: ${currencyFormat.format(account.availableBalance)} de ${currencyFormat.format(account.creditLimit)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                          ),
                    ),
                  ),
              ],
            ),
          ),

          // Detalles
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Info adicional
                  if (account.bankName != null || account.lastFourDigits != null)
                    _buildInfoCard(context, [
                      if (account.bankName != null)
                        _InfoRow(
                          icon: Icons.business,
                          label: 'Banco',
                          value: account.bankName!,
                        ),
                      if (account.lastFourDigits != null)
                        _InfoRow(
                          icon: Icons.pin,
                          label: 'Terminacion',
                          value: '****${account.lastFourDigits}',
                        ),
                    ]),

                  _buildInfoCard(context, [
                    _InfoRow(
                      icon: Icons.currency_exchange,
                      label: 'Moneda',
                      value: account.currency,
                    ),
                    _InfoRow(
                      icon: account.includeInTotal
                          ? Icons.check_circle
                          : Icons.cancel,
                      label: 'En patrimonio',
                      value: account.includeInTotal ? 'Si' : 'No',
                    ),
                    if (account.createdAt != null)
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Creada',
                        value: DateFormat('dd/MM/yyyy').format(account.createdAt!),
                      ),
                  ]),

                  const SizedBox(height: AppSpacing.lg),

                  // Acciones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) =>
                                  AddAccountSheet(account: account),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteConfirmation(context, ref),
                          icon: Icon(Icons.delete, color: AppColors.error),
                          label: Text(
                            'Eliminar',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<_InfoRow> rows) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: rows
              .map((row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          row.icon,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          row.label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          row.value,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          'Estas seguro de eliminar "${account.name}"?\n\n'
          'Solo se pueden eliminar cuentas sin movimientos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar dialog
              final success = await ref
                  .read(accountsProvider.notifier)
                  .deleteAccount(account.id);

              if (!context.mounted) return;

              if (success) {
                Navigator.pop(context); // Cerrar sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cuenta eliminada'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                // Mostrar error
                final errorMessage = ref.read(accountsProvider).errorMessage ??
                    'No se pudo eliminar la cuenta';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
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
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}
