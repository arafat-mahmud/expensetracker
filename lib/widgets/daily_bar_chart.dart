import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';

/// Daily spending bars for the last [days] days (key 1 = oldest, [days] =
/// today), with a dashed line at the average of the days with spending
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);
    final l = AppLocalizations.of(context);

    final values = dailyExpense.values;
    final maxY = values.fold(0.0, (max, v) => v > max ? v : max);
    final spendingDays = values.where((v) => v > 0);
    final average = spendingDays.isEmpty
        ? 0.0
        : spendingDays.reduce((a, b) => a + b) / spendingDays.length;
    final top = maxY > 0 ? maxY * 1.25 : 100.0;
    final today = DateTime.now();
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final labelEvery = days <= 7 ? 1 : (days <= 14 ? 2 : 5);
    final barWidth = days <= 7 ? 18.0 : (days <= 14 ? 10.0 : 6.0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              AppFormat.money(context, rod.toY, decimals: 0),
              textTheme.labelMedium!.copyWith(
                color: scheme.onInverseSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: top / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                final label = value >= 1000
                    ? '${AppFormat.number(context, value / 1000)}k'
                    : AppFormat.number(context, value);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(label,
                      style: labelStyle, textAlign: TextAlign.right),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final fromEnd = days - index;
                if (fromEnd % labelEvery != 0) return const SizedBox.shrink();
                final date = today.subtract(Duration(days: fromEnd));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(AppFormat.day(context, date), style: labelStyle),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (average > 0)
              HorizontalLine(
                y: average,
                color: palette.warning,
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.warning,
                    fontWeight: FontWeight.w700,
                  ),
                  labelResolver: (_) =>
                      '${l.average} ${AppFormat.money(context, average, decimals: 0)}',
                ),
              ),
          ],
        ),
        barGroups: [
          for (var day = 1; day <= days; day++)
            BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: dailyExpense[day] ?? 0,
                  width: barWidth,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(barWidth / 2)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.75),
                      scheme.primary,
                    ],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: top,
                    color: scheme.surfaceContainer,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
