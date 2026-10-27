import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_format.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_ui.dart';

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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);

    final transaction = DepositTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: widget.profileId,
      amount: AppFormat.parseAmount(_amountController.text)!,
      type: widget.isDeposit ? 'deposit' : 'withdraw',
      date: _selectedDate,
      note: _noteController.text.trim(),
    );
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);

    showAppSnack(
        context, widget.isDeposit ? l.depositAdded : l.withdrawCompleted);
    Navigator.pop(context);

    // Saved locally at once; the cloud copy syncs in the background
    try {
      await depositProvider.addTransaction(transaction);
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final accent = widget.isDeposit ? palette.income : palette.expense;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isDeposit ? l.addDeposit : l.withdraw),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (!widget.isDeposit && widget.maxWithdraw != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: palette.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l.availableBalance}: ${AppFormat.money(context, widget.maxWithdraw!)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AmountField(
              controller: _amountController,
              label: widget.isDeposit ? l.depositAmount : l.withdrawAmount,
              color: accent,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l.pleaseEnterAmount;
                }
                final amount = AppFormat.parseAmount(value);
                if (amount == null || amount <= 0) {
                  return l.pleaseEnterValidAmount;
                }
                if (!widget.isDeposit &&
                    widget.maxWithdraw != null &&
                    amount > widget.maxWithdraw!) {
                  return l.insufficientBalance;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PickerField(
              label: l.date,
              value: AppFormat.date(context, _selectedDate),
              icon: Icons.calendar_today_rounded,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              minLines: 1,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.noteOptional,
                hintText: l.noteHint,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 28),
            SubmitButton(
              label: widget.isDeposit ? l.addDeposit : l.confirmWithdraw,
              icon: widget.isDeposit
                  ? Icons.savings_rounded
                  : Icons.north_east_rounded,
              color: accent,
              onPressed: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }
}
