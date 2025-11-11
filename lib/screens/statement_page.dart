import 'dart:ui';
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
        context: context,
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
    // Opening balance is 0 for the statement period
    final openingBalance = 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Period Selection
                  _buildSectionHeader(context, 'QUICK SELECT PERIOD'),
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
                      return ChoiceChip(
                        label: Text(period),
                        selected: false,
                        onSelected: (_) => _selectQuickPeriod(period),
                        labelStyle: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Custom Date Range
                  _buildSectionHeader(context, 'CUSTOM DATE RANGE'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectStartDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'START DATE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(_startDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEndDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'END DATE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(_endDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Summary Card - Banking Style
                  _buildSectionHeader(context, 'ACCOUNT SUMMARY'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TRANSACTIONS: ${transactions.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: balance >= 0
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: balance >= 0
                                        ? Colors.green.shade300
                                        : Colors.red.shade300,
                                  ),
                                ),
                                child: Text(
                                  balance >= 0 ? 'SURPLUS' : 'DEFICIT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildProfessionalSummaryRow(
                                'Opening Balance',
                                openingBalance,
                                Colors.blue.shade700,
                              ),
                              const Divider(height: 24),
                              _buildProfessionalSummaryRow(
                                'Total Credits (+)',
                                totalIncome,
                                Colors.green.shade700,
                              ),
                              const SizedBox(height: 12),
                              _buildProfessionalSummaryRow(
                                'Total Debits (-)',
                                totalExpense,
                                Colors.red.shade700,
                              ),
                              const Divider(height: 24),
                              _buildProfessionalSummaryRow(
                                'Closing Balance',
                                balance,
                                balance >= 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                isBold: true,
                                isLarge: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Download Buttons
                  if (_isGenerating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No Transactions Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions found for the selected period.\nPlease adjust your date range.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _generatePdfStatement,
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text(
                        'DOWNLOAD PDF STATEMENT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Footer Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your statement will be downloaded in professional banking format with running balance and transaction details.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProfessionalSummaryRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isLarge ? 20 : 15,
            fontWeight: FontWeight.bold,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
