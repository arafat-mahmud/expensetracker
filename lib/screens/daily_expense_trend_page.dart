import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/expense_provider.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/ui/app_ui.dart';

class DailyExpenseTrendPage extends StatefulWidget {
  const DailyExpenseTrendPage({super.key});

  @override
  State<DailyExpenseTrendPage> createState() => _DailyExpenseTrendPageState();
}

class _DailyExpenseTrendPageState extends State<DailyExpenseTrendPage> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final dailyExpense = expenseProvider.getDailyExpenseForLastNDays(_days);

    final total = dailyExpense.values.fold(0.0, (sum, v) => sum + v);
    final spendingDays = dailyExpense.values.where((v) => v > 0);
    final average =
        spendingDays.isEmpty ? 0.0 : total / spendingDays.length;
    final highest =
        dailyExpense.values.fold(0.0, (max, v) => v > max ? v : max);

    return Scaffold(
      appBar: AppBar(title: Text(l.dailyExpenseTrend)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final days in const [7, 14, 30])
                  ButtonSegment(value: days, label: Text(l.lastNDays(days))),
              ],
              selected: {_days},
              onSelectionChanged: (selection) =>
                  setState(() => _days = selection.first),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.functions_rounded,
                  label: l.total,
                  value: AppFormat.money(context, total, decimals: 0),
                  color: palette.expense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  icon: Icons.show_chart_rounded,
                  label: l.average,
                  value: AppFormat.money(context, average, decimals: 0),
                  color: palette.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MetricTile(
            icon: Icons.arrow_upward_rounded,
            label: l.highestDay,
            value: AppFormat.money(context, highest, decimals: 0),
            color: palette.violet,
          ),
          const SizedBox(height: 16),
          Card(
            child: total == 0
                ? EmptyState(
                    compact: true,
                    icon: Icons.bar_chart_rounded,
                    title: l.noExpensesInPeriod,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                    child: SizedBox(
                      height: 300,
                      child: DailyBarChart(
                        dailyExpense: dailyExpense,
                        days: _days,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
