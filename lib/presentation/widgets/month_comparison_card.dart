import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/services/chart_service.dart';

/// Widget de tarjeta comparativa entre mes actual y anterior
class MonthComparisonCard extends StatelessWidget {
  final PeriodComparison comparison;

  const MonthComparisonCard({
    super.key,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparado con el mes anterior',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ComparisonItem(
                    label: 'Ingresos',
                    current: comparison.currentIncome,
                    previous: comparison.previousIncome,
                    change: comparison.incomeChange,
                    changePercent: comparison.incomeChangePercent,
                    positiveIsGood: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ComparisonItem(
                    label: 'Gastos',
                    current: comparison.currentExpense,
                    previous: comparison.previousExpense,
                    change: comparison.expenseChange,
                    changePercent: comparison.expenseChangePercent,
                    positiveIsGood: false,
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

class _ComparisonItem extends StatelessWidget {
  final String label;
  final double current;
  final double previous;
  final double change;
  final double changePercent;
  final bool positiveIsGood;

  const _ComparisonItem({
    required this.label,
    required this.current,
    required this.previous,
    required this.change,
    required this.changePercent,
    required this.positiveIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final isPositiveChange = change >= 0;
    final isGood = positiveIsGood ? isPositiveChange : !isPositiveChange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(current),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositiveChange
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 16,
                color: isGood ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${isPositiveChange ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isGood ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'vs ${currencyFormat.format(previous)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
