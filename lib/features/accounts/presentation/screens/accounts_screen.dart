import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_provider.dart';
import '../widgets/add_account_sheet.dart';
import '../widgets/account_detail_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    // Escuchar errores
    ref.listen<AccountsState>(accountsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ref.read(accountsProvider.notifier).clearError();
              },
            ),
          ),
        );
        ref.read(accountsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          // Indicador de sincronizacion
          if (accountsState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: accountsState.isSyncing
                ? null
                : () => ref.read(accountsProvider.notifier).syncAccounts(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva cuenta',
            onPressed: () => _showAddAccountSheet(context),
          ),
        ],
      ),
      body: accountsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : accountsState.activeAccounts.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(accountsProvider.notifier).syncAccounts(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Balance total
                      _buildTotalBalance(context, accountsState, currencyFormat),
                      const SizedBox(height: AppSpacing.lg),

                      // Cuentas agrupadas por tipo
                      ...accountsState.accountsByType.entries.map((entry) {
                        return _buildAccountTypeSection(
                          context,
                          type: entry.key,
                          accounts: entry.value,
                          currencyFormat: currencyFormat,
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sin cuentas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Agrega tu primera cuenta para empezar a registrar tus finanzas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalance(
    BuildContext context,
    AccountsState state,
    NumberFormat format,
  ) {
    final isNegative = state.totalBalance < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Patrimonio Neto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
                if (state.isSyncing)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              format.format(state.totalBalance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isNegative ? AppColors.expense : AppColors.primary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Resumen por tipo
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _buildBalanceSummaryChip(
                  context,
                  label: 'Activos',
                  amount: state.balanceByType.entries
                      .where((e) => e.key != AccountType.credit)
                      .fold(0.0, (sum, e) => sum + e.value),
                  format: format,
                  color: AppColors.income,
                ),
                _buildBalanceSummaryChip(
                  context,
                  label: 'Deudas',
                  amount: state.balanceByType[AccountType.credit] ?? 0.0,
                  format: format,
                  color: AppColors.expense,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryChip(
    BuildContext context, {
    required String label,
    required double amount,
    required NumberFormat format,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ${format.format(amount.abs())}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeSection(
    BuildContext context, {
    required AccountType type,
    required List<AccountModel> accounts,
    required NumberFormat currencyFormat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            type.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ),
        ...accounts.map((account) => _buildAccountCard(
              context,
              account: account,
              currencyFormat: currencyFormat,
            )),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required AccountModel account,
    required NumberFormat currencyFormat,
  }) {
    final isNegative = account.balance < 0 || account.type == AccountType.credit;
    final color = _parseColor(account.color);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showAccountDetail(context, account),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _getAccountIcon(account.type),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (!account.isSynced)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.xs),
                            child: Icon(
                              Icons.cloud_off,
                              size: 14,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (account.bankName != null) ...[
                          Text(
                            account.bankName!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                          if (account.lastFourDigits != null)
                            Text(
                              ' ****${account.lastFourDigits}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                        ] else
                          Text(
                            account.currency,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(account.balance.abs()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isNegative
                              ? AppColors.expense
                              : AppColors.textPrimaryLight,
                        ),
                  ),
                  if (account.type == AccountType.credit &&
                      account.creditLimit > 0)
                    Text(
                      'Disponible: ${currencyFormat.format(account.availableBalance)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddAccountSheet(),
    );
  }

  void _showAccountDetail(BuildContext context, AccountModel account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AccountDetailSheet(account: account),
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
