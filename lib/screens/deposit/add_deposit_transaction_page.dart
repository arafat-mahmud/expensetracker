import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';

class AddDepositTransactionPage extends StatefulWidget {
  final String profileId;
  final bool isDeposit;
  final double? maxWithdraw;

  const AddDepositTransactionPage({
    super.key,
    required this.profileId,
    required this.isDeposit,
    this.maxWithdraw,
  });

  @override
  State<AddDepositTransactionPage> createState() =>
      _AddDepositTransactionPageState();
}

class _AddDepositTransactionPageState extends State<AddDepositTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final localizations = AppLocalizations.of(context);
      final amount = double.parse(_amountController.text.trim());

      final transaction = DepositTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        profileId: widget.profileId,
        amount: amount,
        type: widget.isDeposit ? 'deposit' : 'withdraw',
        date: _selectedDate,
        note: _noteController.text.trim(),
      );

      final depositProvider =
          Provider.of<DepositProvider>(context, listen: false);

      // Show instant feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  widget.isDeposit ? Icons.add_circle : Icons.remove_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(widget.isDeposit
                    ? localizations.depositAdded
                    : localizations.withdrawCompleted),
              ],
            ),
            backgroundColor: widget.isDeposit ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Close the page immediately
      if (mounted) Navigator.pop(context);

      // Save in background
      try {
        await depositProvider.addTransaction(transaction);
      } catch (e) {
        print('Background sync error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final accentColor = widget.isDeposit ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: accentColor,
        title: Text(
          widget.isDeposit ? localizations.addDeposit : localizations.withdraw,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info banner
            if (!widget.isDeposit && widget.maxWithdraw != null)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${localizations.availableBalance}: ${widget.maxWithdraw!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Field
                    _buildFormCard(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: widget.isDeposit
                              ? localizations.depositAmount
                              : localizations.withdrawAmount,
                          hintText: '0.00',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.isDeposit
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              color: accentColor,
                            ),
                          ),
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizations.pleaseEnterAmount;
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return localizations.pleaseEnterValidAmount;
                          }
                          if (!widget.isDeposit &&
                              widget.maxWithdraw != null &&
                              amount > widget.maxWithdraw!) {
                            return localizations.insufficientBalance;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    _buildFormCard(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: localizations.date,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.calendar_today_rounded,
                                    color: Colors.blue[600]),
                              ),
                              border: InputBorder.none,
                              labelStyle: TextStyle(color: Colors.grey[600]),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note Field
                    _buildFormCard(
                      child: TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: localizations.noteOptional,
                          hintText: 'Add a note...',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.note_rounded,
                                color: Colors.purple[600]),
                          ),
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _saveTransaction,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.isDeposit
                                      ? Icons.savings_rounded
                                      : Icons.money_off_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isDeposit
                                      ? localizations.addDeposit
                                      : localizations.confirmWithdraw,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}
