import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/services/chart_service.dart';

/// Widget de gráfico de línea para tendencia mensual
class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTrendData> data;
  final double? height;
  final bool showBalance;

  const MonthlyTrendChart({
    super.key,
    required this.data,
    this.height,
    this.showBalance = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height ?? 200,
        child: const Center(
          child: Text(
            'Sin datos de tendencia',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final maxY = _calculateMaxY();
    final minY = showBalance ? _calculateMinY() : 0.0;

    return SizedBox(
      height: height ?? 250,
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 50,
                      getTitlesWidget: _leftTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    left: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  // Línea de ingresos
                  LineChartBarData(
                    spots: _buildIncomeSpots(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                  // Línea de gastos
                  LineChartBarData(
                    spots: _buildExpenseSpots(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withValues(alpha: 0.1),
                    ),
                  ),
                  // Línea de balance (opcional)
                  if (showBalance)
                    LineChartBarData(
                      spots: _buildBalanceSpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: _buildTooltipItems,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    double max = 0;
    for (final item in data) {
      if (item.income > max) max = item.income;
      if (item.expense > max) max = item.expense;
      if (showBalance && item.balance > max) max = item.balance;
    }
    // Evitar valores cero que causan error en fl_chart
    if (max == 0) return 100;
    return max * 1.2; // 20% extra para espacio
  }

  double _calculateMinY() {
    double min = 0;
    for (final item in data) {
      if (item.balance < min) min = item.balance;
    }
    return min < 0 ? min * 1.2 : 0;
  }

  List<FlSpot> _buildIncomeSpots() {
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.income))
        .toList();
  }

  List<FlSpot> _buildExpenseSpots() {
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
        .toList();
  }

  List<FlSpot> _buildBalanceSpots() {
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.balance))
        .toList();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }

    final monthFormat = DateFormat('MMM', 'es');
    final text = monthFormat.format(data[index].month);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      text = value.toStringAsFixed(0);
    }

    return Text(
      text,
      style: const TextStyle(fontSize: 10),
      textAlign: TextAlign.right,
    );
  }

  List<LineTooltipItem?> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return touchedSpots.map((spot) {
      String label;
      Color color;

      if (spot.barIndex == 0) {
        label = 'Ingresos: ${currencyFormat.format(spot.y)}';
        color = Colors.green;
      } else if (spot.barIndex == 1) {
        label = 'Gastos: ${currencyFormat.format(spot.y)}';
        color = Colors.red;
      } else {
        label = 'Balance: ${currencyFormat.format(spot.y)}';
        color = Colors.blue;
      }

      return LineTooltipItem(
        label,
        TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _LegendItem(color: Colors.green, label: 'Ingresos'),
        const SizedBox(width: 16),
        const _LegendItem(color: Colors.red, label: 'Gastos'),
        if (showBalance) ...[
          const SizedBox(width: 16),
          const _LegendItem(color: Colors.blue, label: 'Balance', isDashed: true),
        ],
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed
                ? Border.all(color: color, width: 1)
                : null,
          ),
          child: isDashed
              ? CustomPaint(
                  painter: _DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
