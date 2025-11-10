import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/daily_bar_chart.dart';

class DailyExpenseTrendPage extends StatefulWidget {
  const DailyExpenseTrendPage({super.key});

  @override
  State<DailyExpenseTrendPage> createState() => _DailyExpenseTrendPageState();
}

class _DailyExpenseTrendPageState extends State<DailyExpenseTrendPage> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final dailyExpense = expenseProvider.getDailyExpenseForLastNDays(_days);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Expense Trend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Show last:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _days,
                  items: [7, 14, 30].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value days'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _days = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: dailyExpense.isEmpty
                  ? const Center(child: Text('No expenses in this period'))
                  : DailyBarChart(
                      dailyExpense: dailyExpense,
                      days: _days,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
