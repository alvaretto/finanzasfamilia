import 'package:flutter/material.dart';

import '../../../ai_assistant/presentation/screens/ai_chat_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openAIChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AIChatScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas Familiares'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            _BalanceCard(),
            const SizedBox(height: 16),
            // Quick Actions Row
            _QuickActionsRow(),
            const SizedBox(height: 24),
            // Assets & Liabilities
            Row(
              children: [
                Expanded(child: _SummaryCard(
                  title: 'Lo que Tengo',
                  amount: 2100000,
                  color: Colors.green,
                  icon: Icons.account_balance_wallet,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(
                  title: 'Lo que Debo',
                  amount: 650000,
                  color: Colors.red,
                  icon: Icons.credit_card,
                )),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Transactions
            Text(
              'Transacciones Recientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _TransactionTile(
              icon: Icons.shopping_cart,
              title: 'Mercado D1',
              category: 'Alimentación',
              amount: -85000,
              date: 'Hoy',
            ),
            _TransactionTile(
              icon: Icons.local_gas_station,
              title: 'Gasolina',
              category: 'Transporte',
              amount: -120000,
              date: 'Ayer',
            ),
            _TransactionTile(
              icon: Icons.payments,
              title: 'Salario',
              category: 'Ingresos',
              amount: 3500000,
              date: '1 Ene',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAIChat(context),
        tooltip: 'Asistente IA',
        child: const Icon(Icons.chat),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Transacciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo Total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$1,450,000',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  '+\$150,000 este mes',
                  style: TextStyle(color: Colors.green[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickAction(icon: Icons.add, label: 'Ingreso', color: Colors.green),
        _QuickAction(icon: Icons.remove, label: 'Gasto', color: Colors.red),
        _QuickAction(icon: Icons.swap_horiz, label: 'Transfer', color: Colors.blue),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withAlpha(30),
          radius: 24,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = '\$${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatted,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final double amount;
  final String date;

  const _TransactionTile({
    required this.icon,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = amount < 0;
    final formatted = '${isExpense ? "-" : "+"}\$${amount.abs().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isExpense ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30),
        child: Icon(icon, color: isExpense ? Colors.red : Colors.green),
      ),
      title: Text(title),
      subtitle: Text(category),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatted,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
          Text(date, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
