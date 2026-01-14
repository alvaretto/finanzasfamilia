import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/home_widget_provider.dart';
import '../../application/services/quick_actions_service.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'transaction_form_screen.dart';
import 'account_form_screen.dart';
import 'ai_chat_screen.dart';
import 'savings_goals_screen.dart';

/// Provider para el índice de navegación actual
final currentTabProvider = StateProvider<int>((ref) => 0);

/// Provider para la acción rápida pendiente de procesar
final pendingQuickActionProvider = StateProvider<QuickActionType?>((ref) => null);

/// Shell principal de la aplicación con Bottom Navigation
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    CategoriesScreen(),
    BudgetsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initQuickActions();
  }

  void _initQuickActions() {
    final quickActionsService = ref.read(quickActionsServiceProvider);
    quickActionsService.initialize(
      onAction: (action) {
        // Guardar la acción para procesarla después del build
        ref.read(pendingQuickActionProvider.notifier).state = action;
      },
    );
  }

  void _handlePendingQuickAction(QuickActionType? action) {
    if (action == null) return;

    // Limpiar la acción pendiente
    ref.read(pendingQuickActionProvider.notifier).state = null;

    // Ejecutar la acción
    switch (action) {
      case QuickActionType.newExpense:
        _openTransactionForm(context, initialType: 'expense');
      case QuickActionType.newIncome:
        _openTransactionForm(context, initialType: 'income');
      case QuickActionType.viewBalance:
        ref.read(currentTabProvider.notifier).state = 0; // Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    // Sincronizar widget de home screen con el saldo
    ref.watch(homeWidgetSyncProvider);

    // Procesar acciones rápidas pendientes
    final pendingAction = ref.watch(pendingQuickActionProvider);
    if (pendingAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePendingQuickAction(pendingAction);
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '¿Cómo Voy?',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Presupuestos',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FAB del Asistente IA
          FloatingActionButton.small(
            heroTag: 'ai_assistant',
            onPressed: () => _openAIChat(context),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: const Text('🤖', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 8),
          // FAB principal para agregar
          FloatingActionButton.extended(
            heroTag: 'add_transaction',
            onPressed: () => _showAddTransactionSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Transacción'),
          ),
        ],
      ),
    );
  }

  void _openAIChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatScreen()),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _QuickAddSheet(),
    );
  }

  void _openTransactionForm(BuildContext context, {required String initialType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(initialType: initialType),
      ),
    );
  }
}

/// Sheet de acceso rápido para agregar transacciones
class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              const Text(
                '¿Qué quieres registrar?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _QuickActionTile(
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                      title: 'Gasto',
                      subtitle: 'Registrar un gasto',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionFormScreen(
                              initialType: 'expense',
                            ),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.arrow_downward,
                      color: Colors.green,
                      title: 'Ingreso',
                      subtitle: 'Registrar un ingreso',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionFormScreen(
                              initialType: 'income',
                            ),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.swap_horiz,
                      color: Colors.blue,
                      title: 'Transferencia',
                      subtitle: 'Mover dinero entre cuentas',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionFormScreen(
                              initialType: 'transfer',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32),
                    _QuickActionTile(
                      icon: Icons.account_balance_wallet,
                      color: Colors.purple,
                      title: 'Nueva Cuenta',
                      subtitle: 'Agregar billetera o cuenta',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountFormScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.flag,
                      color: Colors.teal,
                      title: 'Metas de Ahorro',
                      subtitle: 'Ver y crear metas',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavingsGoalsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
