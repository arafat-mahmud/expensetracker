import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../services/statement_service.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({super.key});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _generatePdfStatement() async {
    setState(() => _isGenerating = true);

    try {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);

      // Get transactions for the period
      final transactions =
          expenseProvider.filterByDateRange(_startDate, _endDate);

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;

      for (var transaction in transactions) {
        if (transaction.isCredit) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      final balance = totalIncome - totalExpense;

      await StatementService.generatePdfStatement(
        startDate: _startDate,
        endDate: _endDate,
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF statement generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _generateCsvStatement() async {
    setState(() => _isGenerating = true);

    try {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);

      // Get transactions for the period
      final transactions =
          expenseProvider.filterByDateRange(_startDate, _endDate);

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;

      for (var transaction in transactions) {
        if (transaction.isCredit) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      final balance = totalIncome - totalExpense;

      await StatementService.generateCsvStatement(
        startDate: _startDate,
        endDate: _endDate,
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV statement generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _selectQuickPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      switch (period) {
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'Last 3 Months':
          _startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'Last 6 Months':
          _startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          break;
        case 'Last 30 Days':
          _startDate = now.subtract(const Duration(days: 30));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final transactions =
        expenseProvider.filterByDateRange(_startDate, _endDate);

    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in transactions) {
      if (transaction.isCredit) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Statement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a date range to generate your account statement',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Period Selection
            Text(
              'Quick Select',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Last 30 Days',
                'This Month',
                'Last Month',
                'Last 3 Months',
                'Last 6 Months',
                'This Year',
              ].map((period) {
                return ActionChip(
                  label: Text(period),
                  onPressed: () => _selectQuickPeriod(period),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Custom Date Range
            Text(
              'Custom Date Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_startDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_endDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statement Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow('Transactions', '${transactions.length}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Total Income',
                      '৳${totalIncome.toStringAsFixed(2)}',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Total Expense',
                      '৳${totalExpense.toStringAsFixed(2)}',
                      color: Colors.red,
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Balance',
                      '৳${balance.toStringAsFixed(2)}',
                      color: balance >= 0 ? Colors.green : Colors.red,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Download Buttons
            if (_isGenerating)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: transactions.isEmpty ? null : _generatePdfStatement,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download PDF Statement'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: transactions.isEmpty ? null : _generateCsvStatement,
                icon: const Icon(Icons.table_chart),
                label: const Text('Download CSV Statement'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No transactions found for the selected period',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
