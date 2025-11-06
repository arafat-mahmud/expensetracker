import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense_model.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryExpense;

  const CategoryPieChart({
    super.key,
    required this.categoryExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryExpense.isEmpty) {
      return const Center(
        child: Text('No expense data available'),
      );
    }

    final total = categoryExpense.values.fold(0.0, (sum, value) => sum + value);

    return PieChart(
      PieChartData(
        sections: categoryExpense.entries.map((entry) {
          final color = Color(
            ExpenseCategory.getCategoryColor(entry.key)['color']!,
          );
          final percentage = (entry.value / total * 100);

          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                ExpenseCategory.getIcon(entry.key),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            badgePositionPercentageOffset: 1.2,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }
}
