import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/report_model.dart';

class TrendLineChart extends StatelessWidget {
  final List<DailyTrendData> data;
  final bool showAccumulated;

  const TrendLineChart({
    super.key,
    required this.data,
    this.showAccumulated = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Sin datos de tendencia',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      );
    }

    final maxY = showAccumulated
        ? data.fold<double>(0, (max, item) => item.accumulated > max ? item.accumulated : max)
        : data.fold<double>(0, (max, item) => item.amount > max ? item.amount : max);

    final roundedMaxY = maxY > 0 ? ((maxY / 1000).ceil() * 1000).toDouble() : 1000.0;
    final interval = roundedMaxY / 4;

    // Solo mostrar algunos puntos en el eje X
    final labelInterval = (data.length / 6).ceil();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final format = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
                      final dateFormat = DateFormat('dd/MM', 'es');
                      final dataPoint = data[spot.spotIndex];
                      return LineTooltipItem(
                        '${dateFormat.format(dataPoint.date)}\n${format.format(spot.y)}',
                        TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: labelInterval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final date = data[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd', 'es').format(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '${(value / 1000).toStringAsFixed(0)}k',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: roundedMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    final value = showAccumulated ? entry.value.accumulated : entry.value.amount;
                    return FlSpot(entry.key.toDouble(), value);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.expense,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.expense.withValues(alpha: 0.3),
                        AppColors.expense.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          showAccumulated ? 'Gasto acumulado del periodo' : 'Gasto diario',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
