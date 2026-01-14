import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/accounting_provider.dart';
import '../../application/providers/dashboard_provider.dart';
import '../../application/providers/financial_indicators_provider.dart';
import '../widgets/traffic_light_indicator.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// Pantalla principal del Dashboard "¿Cómo Voy?"
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardSummaryProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Cómo Voy?'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            tooltip: 'Reportes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(totalBalanceProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (dashboard) => _DashboardContent(
          dashboard: dashboard,
          totalBalance: totalBalanceAsync.valueOrNull,
        ),
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
                onPressed: () => ref.invalidate(dashboardSummaryProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary dashboard;
  final TotalBalance? totalBalance;

  const _DashboardContent({
    required this.dashboard,
    this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () async {
        // El refresh se maneja con invalidate
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de Patrimonio Neto (usa totalBalance si disponible)
          _NetWorthCard(
            netWorth: totalBalance?.netWorth ?? dashboard.netWorth,
            totalAssets: totalBalance?.assets ?? dashboard.totalAssets,
            totalLiabilities: totalBalance?.liabilities ?? dashboard.totalLiabilities,
            accountCount: totalBalance?.accountCount,
            currencyFormat: currencyFormat,
          ),

          const SizedBox(height: 16),

          // Tarjeta de Saldo Disponible Real
          _AvailableBalanceCard(
            availableBalance: totalBalance?.balance ?? dashboard.availableBalance,
            currencyFormat: currencyFormat,
          ),

          const SizedBox(height: 16),

          // Resumen del Mes
          _MonthSummaryCard(
            monthSummary: dashboard.currentMonth,
            currencyFormat: currencyFormat,
          ),

          const SizedBox(height: 16),

          // Alertas de Presupuesto (Semáforos)
          if (dashboard.budgetAlerts.isNotEmpty) ...[
            _BudgetAlertsSection(
              alerts: dashboard.budgetAlerts,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 16),
          ],

          // Gastos por Categoría
          _ExpensesByCategorySection(
            expenses: dashboard.expensesByCategory,
            totalExpenses: dashboard.totalExpenses,
            currencyFormat: currencyFormat,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de Patrimonio Neto ("Mis Ahorros Netos")
class _NetWorthCard extends StatelessWidget {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final int? accountCount;
  final NumberFormat currencyFormat;

  const _NetWorthCard({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    this.accountCount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netWorth >= 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mis Ahorros Netos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (accountCount != null)
                  Text(
                    '$accountCount cuentas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormat.format(netWorth),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'Lo que Tengo',
                  value: currencyFormat.format(totalAssets),
                  color: Colors.green,
                ),
                _MiniStat(
                  label: 'Lo que Debo',
                  value: currencyFormat.format(totalLiabilities),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de Saldo Disponible Real
class _AvailableBalanceCard extends StatelessWidget {
  final double availableBalance;
  final NumberFormat currencyFormat;

  const _AvailableBalanceCard({
    required this.availableBalance,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = availableBalance >= 0;

    return Card(
      color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.warning,
              color: isPositive ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Disponible Real',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    currencyFormat.format(availableBalance),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de Resumen del Mes
class _MonthSummaryCard extends StatelessWidget {
  final MonthSummary monthSummary;
  final NumberFormat currencyFormat;

  const _MonthSummaryCard({
    required this.monthSummary,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de ${monthNames[monthSummary.month]} ${monthSummary.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.arrow_downward,
                  label: 'Ingresos',
                  value: currencyFormat.format(monthSummary.incomeTotal),
                  color: Colors.green,
                ),
                _SummaryItem(
                  icon: Icons.arrow_upward,
                  label: 'Gastos',
                  value: currencyFormat.format(monthSummary.expenseTotal),
                  color: Colors.red,
                ),
                _SummaryItem(
                  icon: Icons.balance,
                  label: 'Balance',
                  value: currencyFormat.format(monthSummary.netBalance),
                  color: monthSummary.netBalance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de Alertas de Presupuesto (Semáforos)
class _BudgetAlertsSection extends StatelessWidget {
  final List<BudgetAlert> alerts;
  final NumberFormat currencyFormat;

  const _BudgetAlertsSection({
    required this.alerts,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Alertas de Presupuesto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...alerts.map((alert) => _BudgetAlertTile(
              alert: alert,
              currencyFormat: currencyFormat,
            )),
          ],
        ),
      ),
    );
  }
}

class _BudgetAlertTile extends StatelessWidget {
  final BudgetAlert alert;
  final NumberFormat currencyFormat;

  const _BudgetAlertTile({
    required this.alert,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final data = TrafficLightData(
      spent: alert.spentAmount,
      budgetAmount: alert.budgetAmount,
      percentage: alert.percentage,
      status: _mapStatus(alert.status),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          TrafficLightIndicator(data: data, compact: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${currencyFormat.format(alert.spentAmount)} de ${currencyFormat.format(alert.budgetAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${alert.percentage.toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: alert.isOverBudget ? Colors.red : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  TrafficLightStatus _mapStatus(IndicatorStatus status) {
    switch (status) {
      case IndicatorStatus.good:
        return TrafficLightStatus.safe;
      case IndicatorStatus.warning:
        return TrafficLightStatus.warning;
      case IndicatorStatus.danger:
        return TrafficLightStatus.exceeded;
    }
  }
}

/// Sección de Gastos por Categoría
class _ExpensesByCategorySection extends StatelessWidget {
  final List<CategoryExpense> expenses;
  final double totalExpenses;
  final NumberFormat currencyFormat;

  const _ExpensesByCategorySection({
    required this.expenses,
    required this.totalExpenses,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay gastos este mes'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos por Categoría',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(),
            ...expenses.take(5).map((expense) => _ExpenseCategoryTile(
              expense: expense,
              currencyFormat: currencyFormat,
            )),
            if (expenses.length > 5)
              TextButton(
                onPressed: () {
                  // Navegar al tab de estadísticas para ver desglose completo
                  Navigator.of(context).pushNamed('/statistics');
                },
                child: Text('Ver todos (${expenses.length})'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCategoryTile extends StatelessWidget {
  final CategoryExpense expense;
  final NumberFormat currencyFormat;

  const _ExpenseCategoryTile({
    required this.expense,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (expense.icon != null) ...[
            Text(expense.icon!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.categoryName),
                LinearProgressIndicator(
                  value: expense.percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    _getProgressColor(expense.percentage),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(expense.amount),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${expense.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 30) return Colors.red;
    if (percentage >= 20) return Colors.orange;
    return Colors.blue;
  }
}

// Widgets auxiliares

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
