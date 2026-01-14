import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/accounting_provider.dart';
import 'account_form_screen.dart';

/// Pantalla de listado de cuentas (billeteras, bancos, etc.)
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(activeAccountsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(activeAccountsProvider);
              ref.invalidate(totalBalanceProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tarjeta de balance total
          _TotalBalanceCard(totalBalanceAsync: totalBalanceAsync),

          // Lista de cuentas
          Expanded(
            child: accountsAsync.when(
              data: (accounts) => _AccountsList(accounts: accounts),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(activeAccountsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Tarjeta con el balance total
class _TotalBalanceCard extends StatelessWidget {
  final AsyncValue<TotalBalance> totalBalanceAsync;

  const _TotalBalanceCard({required this.totalBalanceAsync});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return totalBalanceAsync.when(
      data: (totalBalance) {
        final isPositive = totalBalance.balance >= 0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? [Colors.green.shade600, Colors.green.shade400]
                  : [Colors.red.shade600, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(totalBalance.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${totalBalance.accountCount} cuenta${totalBalance.accountCount != 1 ? 's' : ''} activa${totalBalance.accountCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.all(16),
        height: 120,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Error cargando balance'),
        ),
      ),
    );
  }
}

/// Lista de cuentas
class _AccountsList extends ConsumerWidget {
  final List<AccountWithCategoryDto> accounts;

  const _AccountsList({required this.accounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay cuentas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera cuenta para comenzar',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeAccountsProvider);
        ref.invalidate(totalBalanceProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          return _AccountTile(accountData: accounts[index]);
        },
      ),
    );
  }
}

/// Tile individual de cuenta
class _AccountTile extends ConsumerWidget {
  final AccountWithCategoryDto accountData;

  const _AccountTile({required this.accountData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = accountData.account;
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final color = account.color != null
        ? Color(int.parse(account.color!.replaceFirst('#', '0xFF')))
        : Colors.green;

    final isPositive = account.balance >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _openAccountDetail(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de cuenta
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    account.icon ?? '💰',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info de cuenta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (account.isSystem)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 10,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Predefinida',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (account.isSystem && !account.includeInTotal)
                          const SizedBox(width: 4),
                        if (!account.includeInTotal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'No suma',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        if (account.description != null &&
                            account.description!.isNotEmpty) ...[
                          if (account.isSystem || !account.includeInTotal)
                            const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              account.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(account.balance),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    account.currency,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              // Chevron
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAccountDetail(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: accountData.account),
      ),
    );

    if (result == true) {
      ref.invalidate(activeAccountsProvider);
      ref.invalidate(totalBalanceProvider);
    }
  }
}
