import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/account_provider.dart';
import '../models/account_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/ui/app_ui.dart';
import 'add_expense_page.dart';
import 'add_income_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _filterCategory = 'All';
  String _transactionType = 'All'; // 'All', 'Debit', 'Credit'
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    // Reload local data
    expenseProvider.loadExpenses();

    // Changes from other devices already arrive through the live listener,
    // so this only (re)starts it if it is not running. No reads otherwise.
    await expenseProvider.startCloudSync();
  }

  List<Expense> _filtered(ExpenseProvider provider, AppLocalizations l) {
    Iterable<Expense> expenses = provider.expenses;
    if (_transactionType == 'Debit') {
      expenses = expenses.where((e) => e.isDebit);
    } else if (_transactionType == 'Credit') {
      expenses = expenses.where((e) => e.isCredit);
    }
    if (_filterCategory != 'All') {
      expenses = expenses.where((e) => e.category == _filterCategory);
    }
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      expenses = expenses.where((e) =>
          e.title.toLowerCase().contains(query) ||
          e.note.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query) ||
          l.getCategoryName(e.category).toLowerCase().contains(query));
    }
    return expenses.toList();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final l = AppLocalizations.of(context);
    final expenses = _filtered(expenseProvider, l);

    // Group by day; the provider already sorts newest first
    final groups = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final day =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      groups.putIfAbsent(day, () => []).add(expense);
    }

    final categories = [
      if (_transactionType != 'Credit') ...ExpenseCategory.all,
      if (_transactionType != 'Debit') ...IncomeCategory.all,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.history),
        actions: [
          if (Provider.of<AccountProvider>(context)
              .isEnabled(AppFeature.statement))
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: l.downloadStatement,
              onPressed: () => Navigator.pushNamed(context, '/statement'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchTransactions,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'All', label: Text(l.all)),
                  ButtonSegment(value: 'Debit', label: Text(l.expenses)),
                  ButtonSegment(value: 'Credit', label: Text(l.income)),
                ],
                selected: {_transactionType},
                onSelectionChanged: (selection) => setState(() {
                  _transactionType = selection.first;
                  _filterCategory = 'All';
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: l.all,
                  selected: _filterCategory == 'All',
                  onSelected: () => setState(() => _filterCategory = 'All'),
                ),
                for (final category in categories)
                  _CategoryChip(
                    emoji: ExpenseCategory.all.contains(category)
                        ? ExpenseCategory.getIcon(category)
                        : IncomeCategory.getIcon(category),
                    label: l.getCategoryName(category),
                    selected: _filterCategory == category,
                    onSelected: () =>
                        setState(() => _filterCategory = category),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: expenses.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: l.noExpensesFound,
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        for (final entry in groups.entries) ...[
                          _DayHeader(day: entry.key, items: entry.value),
                          Card(
                            child: Column(
                              children: [
                                for (var i = 0;
                                    i < entry.value.length;
                                    i++) ...[
                                  if (i > 0) const Divider(indent: 72),
                                  ExpenseCard(
                                    expense: entry.value[i],
                                    showDate: false,
                                    onEdit: () => _edit(entry.value[i]),
                                    onDelete: () => confirmAndDeleteExpense(
                                        context,
                                        entry.value[i],
                                        expenseProvider.deleteExpense),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 1),
    );
  }

  void _edit(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => expense.isDebit
            ? AddExpensePage(expense: expense)
            : AddIncomePage(income: expense),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        avatar: emoji == null ? null : Text(emoji!),
        label: Text(label),
      ),
    );
  }
}

/// "Today" / "Yesterday" / date, with the day's net total
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.items});

  final DateTime day;
  final List<Expense> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    final now = DateTime.now();
    final label = AppFormat.isSameDay(day, now)
        ? l.today
        : AppFormat.isSameDay(day, now.subtract(const Duration(days: 1)))
            ? l.yesterday
            : AppFormat.longDate(context, day);
    final net =
        items.fold(0.0, (sum, e) => sum + (e.isCredit ? e.amount : -e.amount));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            AppFormat.money(context, net, signed: true),
            style: textTheme.labelLarge?.copyWith(
              color: net >= 0 ? palette.income : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
