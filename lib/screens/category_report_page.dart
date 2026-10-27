import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/ui/app_ui.dart';
import '../theme/app_format.dart';
import 'add_expense_page.dart';
import '../l10n/app_localizations.dart';

class CategoryReportPage extends StatefulWidget {
  final String category;

  const CategoryReportPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryReportPage> createState() => _CategoryReportPageState();
}

class _CategoryReportPageState extends State<CategoryReportPage> {
  Future<void> _handleRefresh() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    // Reload local data
    expenseProvider.loadExpenses();

    // Changes from other devices already arrive through the live listener,
    // so this only (re)starts it if it is not running. No reads otherwise.
    await expenseProvider.startCloudSync();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.getExpensesByCategory(widget.category);
    final totalAmount =
        expenseProvider.getTotalExpenseForCategory(widget.category);
    final color =
        Color(ExpenseCategory.getCategoryColor(widget.category)['color']!);

    return Scaffold(
      appBar: AppBar(title: Text(l.getCategoryName(widget.category))),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  IconBadge(
                    emoji: ExpenseCategory.getIcon(widget.category),
                    color: color,
                    size: 56,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.total,
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppFormat.money(context, totalAmount),
                            style: textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: l.transactionCount(expenses.length),
                    color: color,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(l.allTransactions),
            Card(
              child: expenses.isEmpty
                  ? EmptyState(
                      compact: true,
                      icon: Icons.receipt_long_rounded,
                      title: l.noExpensesFound,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < expenses.length; i++) ...[
                          if (i > 0) const Divider(indent: 72),
                          ExpenseCard(
                            expense: expenses[i],
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddExpensePage(expense: expenses[i]),
                              ),
                            ),
                            onDelete: () => confirmAndDeleteExpense(context,
                                expenses[i], expenseProvider.deleteExpense),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
