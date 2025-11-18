import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyBarChart extends StatelessWidget {
  final Map<int, double> dailyExpense;
  final int days;

  const DailyBarChart({
    super.key,
    required this.dailyExpense,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyExpense.isEmpty) {
      return const Center(
        child: Text('No expense data for this month'),
      );
    }

    final maxY = dailyExpense.values
        .fold(0.0, (max, value) => value > max ? value : max);

    // Calculate average expense (only for days with expenses)
    final totalExpense =
        dailyExpense.values.fold(0.0, (sum, value) => sum + value);
    final daysWithExpenses = dailyExpense.values.where((v) => v > 0).length;
    final averageExpense =
        daysWithExpenses > 0 ? totalExpense / daysWithExpenses : 0.0;

    // Calculate proper max Y with some padding
    final scaledMaxY = maxY > 0 ? (maxY * 1.2).toDouble() : 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: scaledMaxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueAccent,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (days <= 7) {
                  final today = DateTime.now();
                  final day =
                      today.subtract(Duration(days: days - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                } else if (days <= 14) {
                  if (value.toInt() % 2 == 0 || value.toInt() == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                } else {
                  if (value.toInt() % 5 == 0 || value.toInt() == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value >= 1000) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${(value / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: scaledMaxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            );
          },
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: averageExpense,
              color: Colors.orange.shade600,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                labelResolver: (line) =>
                    'Avg: ${averageExpense.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        barGroups: _generateBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(days, (index) {
      final day = index + 1;
      final value = dailyExpense[day] ?? 0.0;
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: value,
            fromY: 0,
            color: value > 0 ? Colors.blue : Colors.transparent,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }
}
