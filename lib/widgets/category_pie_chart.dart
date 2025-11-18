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
    final categoryCount = categoryExpense.length;

    // Calculate dynamic height based on number of categories
    // Base: 180 for chart, 8 for spacing, then estimate legend height
    // Each legend item is roughly 22px height, arrange in rows
    final itemsPerRow = 3;
    final legendRows = (categoryCount / itemsPerRow).ceil();
    final legendHeight = (legendRows * 22.0) +
        ((legendRows - 1) * 6.0); // 22px per row + 6px runSpacing
    final totalHeight = 180 + 8 + legendHeight;

    return SizedBox(
      height: totalHeight,
      child: Column(
        children: [
          // Donut Chart
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: categoryExpense.entries.map((entry) {
                  final color = Color(
                    ExpenseCategory.getCategoryColor(entry.key)['color']!,
                  );
                  final percentage = (entry.value / total * 100);

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: null,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: categoryExpense.entries.map((entry) {
              final color = Color(
                ExpenseCategory.getCategoryColor(entry.key)['color']!,
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
