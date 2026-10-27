import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/expense_model.dart';
import '../theme/app_format.dart';

/// Donut chart of spending per category, with the total in the middle
class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryExpense;
  final double size;

  const CategoryPieChart({
    super.key,
    required this.categoryExpense,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = categoryExpense.values.fold(0.0, (sum, v) => sum + v);
    final entries = categoryExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.33,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                for (final entry in entries)
                  PieChartSectionData(
                    color: Color(
                        ExpenseCategory.getCategoryColor(entry.key)['color']!),
                    value: entry.value,
                    radius: size * 0.14,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).total,
                style: textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: size * 0.56,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppFormat.money(context, total, decimals: 0),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
