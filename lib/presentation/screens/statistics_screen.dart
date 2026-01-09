import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/chart_provider.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/month_comparison_card.dart';

/// Pantalla de estadísticas con gráficos financieros
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gastos'),
            Tab(text: 'Tendencia'),
            Tab(text: 'Comparar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExpensesTab(),
          _TrendTab(),
          _ComparisonTab(),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthFormat = DateFormat('MMMM yyyy', 'es');
    final expensesAsync = ref.watch(currentMonthExpensesProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (expenses) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos de ${monthFormat.format(now)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Distribución por categoría',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ExpensePieChart(
                  data: expenses,
                  height: 320,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (expenses.isNotEmpty) ...[
              Text(
                'Detalle por categoría',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildExpensesList(context, expenses),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    List<dynamic> expenses,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = expenses[index];
          return ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(item.color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(item.categoryName),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(item.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendTab extends ConsumerWidget {
  const _TrendTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlyTrendProvider(months: 6));

    return trendAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (trend) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia de 6 meses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresos vs Gastos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MonthlyTrendChart(
                  data: trend,
                  height: 300,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (trend.isNotEmpty) ...[
              Text(
                'Resumen por mes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildMonthlyTable(context, trend),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTable(BuildContext context, List<dynamic> trend) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final monthFormat = DateFormat('MMM', 'es');

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Mes')),
            DataColumn(label: Text('Ingresos'), numeric: true),
            DataColumn(label: Text('Gastos'), numeric: true),
            DataColumn(label: Text('Balance'), numeric: true),
          ],
          rows: trend.map((item) {
            final balance = item.income - item.expense;
            return DataRow(
              cells: [
                DataCell(Text(monthFormat.format(item.month))),
                DataCell(Text(
                  currencyFormat.format(item.income),
                  style: const TextStyle(color: Colors.green),
                )),
                DataCell(Text(
                  currencyFormat.format(item.expense),
                  style: const TextStyle(color: Colors.red),
                )),
                DataCell(Text(
                  currencyFormat.format(balance),
                  style: TextStyle(
                    color: balance >= 0 ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ComparisonTab extends ConsumerWidget {
  const _ComparisonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(monthComparisonProvider);
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM', 'es').format(now);
    final previousMonth = DateFormat('MMMM', 'es').format(
      DateTime(now.year, now.month - 1),
    );

    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (comparison) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$currentMonth vs $previousMonth',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Analiza tu progreso financiero',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            MonthComparisonCard(comparison: comparison),
            const SizedBox(height: 24),
            _buildSummaryCard(context, comparison),
            const SizedBox(height: 24),
            _buildTipsCard(context, comparison),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic comparison) {
    final balanceCurrent =
        comparison.currentIncome - comparison.currentExpense;
    final balancePrevious =
        comparison.previousIncome - comparison.previousExpense;
    final balanceChange = balanceCurrent - balancePrevious;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance del mes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Este mes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(balanceCurrent),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: balanceCurrent >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: balanceChange >= 0
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        balanceChange >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: balanceChange >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currencyFormat.format(balanceChange.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balanceChange >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context, dynamic comparison) {
    final tips = <String>[];

    // Análisis de ingresos
    if (comparison.incomeChangePercent < -10) {
      tips.add('Tus ingresos bajaron significativamente. Revisa tus fuentes de ingreso.');
    } else if (comparison.incomeChangePercent > 10) {
      tips.add('Excelente, tus ingresos aumentaron. Considera ahorrar el extra.');
    }

    // Análisis de gastos
    if (comparison.expenseChangePercent > 20) {
      tips.add('Tus gastos aumentaron mucho. Revisa en qué categorías puedes reducir.');
    } else if (comparison.expenseChangePercent < -10) {
      tips.add('Has reducido tus gastos. Buen trabajo.');
    }

    // Balance general
    final currentBalance = comparison.currentIncome - comparison.currentExpense;
    if (currentBalance < 0) {
      tips.add('Estás gastando más de lo que ganas. Es momento de ajustar.');
    } else if (currentBalance > comparison.currentIncome * 0.2) {
      tips.add('Estás ahorrando más del 20%. Excelente gestión.');
    }

    if (tips.isEmpty) {
      tips.add('Tu gestión financiera se mantiene estable.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Análisis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
