import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/expense_card.dart';
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

  Future<void> _handleRefresh() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    // Reload local data
    expenseProvider.loadExpenses();

    // Try to restore from Firestore (was Google Drive)
    await expenseProvider.restoreFromFirestore();

    // Update last backup time
    await expenseProvider.getLastBackupTime();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text('Transaction history refreshed'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);

    List<Expense> expenses = expenseProvider.expenses;

    // Apply transaction type filter
    if (_transactionType == 'Debit') {
      expenses = expenses.where((e) => e.isDebit).toList();
    } else if (_transactionType == 'Credit') {
      expenses = expenses.where((e) => e.isCredit).toList();
    }

    // Apply category filter
    if (_filterCategory != 'All') {
      expenses = expenses.where((e) => e.category == _filterCategory).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.history,
          style: languageProvider.languageCode == 'bn'
              ? const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )
              : GoogleFonts.rubik80sFade(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Navigator.pushNamed(context, '/statement');
            },
            tooltip: localizations.downloadStatement,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Transaction Type Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'All',
                        label: Text(localizations.all),
                        icon: const Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: 'Debit',
                        label: Text(localizations.expenses),
                        icon: const Icon(Icons.remove_circle),
                      ),
                      ButtonSegment(
                        value: 'Credit',
                        label: Text(localizations.income),
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _transactionType = newSelection.first;
                        _filterCategory = 'All'; // Reset category filter
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                // Show appropriate categories based on transaction type
                if (_transactionType == 'Debit' || _transactionType == 'All')
                  ...ExpenseCategory.all
                      .map((category) => _buildFilterChip(category)),
                if (_transactionType == 'Credit' || _transactionType == 'All')
                  ...IncomeCategory.all
                      .map((category) => _buildFilterChip(category)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transaction List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: expenses.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  localizations.noExpensesFound,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return ExpenseCard(
                          expense: expense,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => expense.isDebit
                                    ? AddExpensePage(expense: expense)
                                    : AddIncomePage(income: expense),
                              ),
                            );
                          },
                          onDelete: () {
                            _showDeleteDialog(
                                context, expense, expenseProvider);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildFilterChip(String category) {
    final localizations = AppLocalizations.of(context);
    final isSelected = _filterCategory == category;
    String icon = '';

    if (category != 'All') {
      // Check if it's an expense category or income category
      if (ExpenseCategory.all.contains(category)) {
        icon = ExpenseCategory.getIcon(category);
      } else if (IncomeCategory.all.contains(category)) {
        icon = IncomeCategory.getIcon(category);
      }
    }

    // Translate 'All' if needed
    final displayText = category == 'All' ? localizations.all : category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(displayText),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterCategory = category;
          });
        },
        avatar: icon.isNotEmpty ? Text(icon) : null,
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Expense expense,
    ExpenseProvider provider,
  ) {
    final itemType = expense.isDebit ? 'expense' : 'income';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Delete ${itemType[0].toUpperCase()}${itemType.substring(1)}'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close dialog immediately
              Navigator.pop(context);

              // Delete expense - instant UI update
              provider.deleteExpense(expense.id);

              // Show feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                          '${itemType[0].toUpperCase()}${itemType.substring(1)} deleted'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/settings');
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: localizations.dashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: localizations.history,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: localizations.settings,
        ),
      ],
    );
  }
}
