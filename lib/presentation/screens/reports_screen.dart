import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/reports_provider.dart';
import '../../domain/services/reports_service.dart';

/// Pantalla principal de Reportes Financieros
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(balanceSheetProvider);
                ref.invalidate(currentMonthIncomeStatementProvider);
                ref.invalidate(currentMonthlySummaryProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumen', icon: Icon(Icons.summarize)),
              Tab(text: 'Balance', icon: Icon(Icons.account_balance)),
              Tab(text: 'Resultados', icon: Icon(Icons.trending_up)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MonthlySummaryTab(),
            _BalanceSheetTab(),
            _IncomeStatementTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab de Resumen Mensual
class _MonthlySummaryTab extends ConsumerWidget {
  const _MonthlySummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(currentMonthlySummaryProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final monthFormat = DateFormat('MMMM yyyy', 'es_CO');

    return summaryAsync.when(
      data: (summary) {
        final monthDate = DateTime(summary.year, summary.month);
        final isPositive = summary.netResult >= 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título del mes
            Text(
              monthFormat.format(monthDate).toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Card de resultado neto
            _ResultCard(
              title: 'Resultado del Mes',
              amount: summary.netResult,
              isPositive: isPositive,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 16),

            // Grid de métricas
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Ingresos',
                    value: currencyFormat.format(summary.totalIncome),
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Gastos',
                    value: currencyFormat.format(summary.totalExpenses),
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Transacciones',
                    value: '${summary.transactionCount}',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Tasa de Ahorro',
                    value: '${summary.savingsRate.toStringAsFixed(1)}%',
                    icon: Icons.savings,
                    color: summary.savingsRate >= 20
                        ? Colors.green
                        : summary.savingsRate >= 0
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gasto diario promedio
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.calendar_today, color: Colors.orange),
                ),
                title: const Text('Gasto Diario Promedio'),
                trailing: Text(
                  currencyFormat.format(summary.avgDailyExpense),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Mayor gasto
            if (summary.topExpenseCategory != null) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    child: const Icon(Icons.trending_up, color: Colors.red),
                  ),
                  title: const Text('Mayor Gasto'),
                  subtitle: Text(summary.topExpenseCategory!),
                  trailing: Text(
                    currencyFormat.format(summary.topExpenseAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

/// Tab de Balance General
class _BalanceSheetTab extends ConsumerWidget {
  const _BalanceSheetTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceSheetProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('d MMMM yyyy', 'es_CO');

    return balanceAsync.when(
      data: (balance) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fecha del balance
            Text(
              'Al ${dateFormat.format(balance.date)}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Patrimonio Neto
            _ResultCard(
              title: 'Patrimonio Neto',
              amount: balance.netWorth,
              isPositive: balance.netWorth >= 0,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 24),

            // Activos
            _SectionHeader(
              title: 'Lo que Tengo (Activos)',
              total: balance.totalAssets,
              color: Colors.green,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 8),
            if (balance.assets.isEmpty)
              const _EmptyMessage(message: 'No hay activos registrados')
            else
              ...balance.assets.map((item) => _BalanceItemTile(
                    item: item,
                    currencyFormat: currencyFormat,
                    isAsset: true,
                  )),

            const SizedBox(height: 24),

            // Pasivos
            _SectionHeader(
              title: 'Lo que Debo (Pasivos)',
              total: balance.totalLiabilities,
              color: Colors.red,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 8),
            if (balance.liabilities.isEmpty)
              const _EmptyMessage(message: 'No hay deudas registradas')
            else
              ...balance.liabilities.map((item) => _BalanceItemTile(
                    item: item,
                    currencyFormat: currencyFormat,
                    isAsset: false,
                  )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

/// Tab de Estado de Resultados
class _IncomeStatementTab extends ConsumerWidget {
  const _IncomeStatementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statementAsync = ref.watch(currentMonthIncomeStatementProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('d MMM', 'es_CO');

    return statementAsync.when(
      data: (statement) {
        final isProfit = statement.netIncome >= 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Período
            Text(
              '${dateFormat.format(statement.startDate)} - ${dateFormat.format(statement.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Resultado Neto
            _ResultCard(
              title: isProfit ? 'Ganancia del Período' : 'Pérdida del Período',
              amount: statement.netIncome.abs(),
              isPositive: isProfit,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 24),

            // Ingresos
            _SectionHeader(
              title: 'Ingresos',
              total: statement.totalIncome,
              color: Colors.green,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 8),
            if (statement.incomeItems.isEmpty)
              const _EmptyMessage(message: 'No hay ingresos este período')
            else
              ...statement.incomeItems.map((item) => _IncomeStatementItemTile(
                    item: item,
                    total: statement.totalIncome,
                    currencyFormat: currencyFormat,
                    isIncome: true,
                  )),

            const SizedBox(height: 24),

            // Gastos
            _SectionHeader(
              title: 'Gastos',
              total: statement.totalExpenses,
              color: Colors.red,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 8),
            if (statement.expenseItems.isEmpty)
              const _EmptyMessage(message: 'No hay gastos este período')
            else
              ...statement.expenseItems.map((item) => _IncomeStatementItemTile(
                    item: item,
                    total: statement.totalExpenses,
                    currencyFormat: currencyFormat,
                    isIncome: false,
                  )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// Widgets auxiliares

class _ResultCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isPositive;
  final NumberFormat currencyFormat;

  const _ResultCard({
    required this.title,
    required this.amount,
    required this.isPositive,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPositive
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${isPositive ? '+' : '-'}${currencyFormat.format(amount.abs())}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double total;
  final Color color;
  final NumberFormat currencyFormat;

  const _SectionHeader({
    required this.title,
    required this.total,
    required this.color,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          Text(
            currencyFormat.format(total),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceItemTile extends StatelessWidget {
  final BalanceItem item;
  final NumberFormat currencyFormat;
  final bool isAsset;

  const _BalanceItemTile({
    required this.item,
    required this.currencyFormat,
    required this.isAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isAsset ? Colors.green : Colors.red).withValues(alpha: 0.2),
          child: Text(
            item.icon ?? '💰',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(item.name),
        subtitle: Text(item.categoryName),
        trailing: Text(
          currencyFormat.format(item.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isAsset ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}

class _IncomeStatementItemTile extends StatelessWidget {
  final IncomeStatementItem item;
  final double total;
  final NumberFormat currencyFormat;
  final bool isIncome;

  const _IncomeStatementItemTile({
    required this.item,
    required this.total,
    required this.currencyFormat,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (item.amount / total) * 100 : 0.0;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  currencyFormat.format(item.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
