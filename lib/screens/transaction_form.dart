import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped_category_dropdown.dart';
import '../widgets/income_category_dropdown.dart';
import '../widgets/ui/app_ui.dart';

/// Add / edit form shared by expenses and income
class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, required this.isIncome, this.existing});

  final bool isIncome;
  final Expense? existing;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _category = widget.existing?.category ??
      (widget.isIncome ? IncomeCategory.salary : ExpenseCategory.other);
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      // Untitled entries store the category key as their title; leave the
      // field empty so it follows the category instead of going stale
      _titleController.text =
          existing.title == existing.category ? '' : existing.title;
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);

    // Use the category as the title when none was entered
    final title = _titleController.text.trim().isEmpty
        ? _category
        : _titleController.text.trim();
    final entry = Expense(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: _category,
      amount: AppFormat.parseAmount(_amountController.text)!,
      date: _date,
      note: _noteController.text.trim(),
      type: widget.isIncome ? 'credit' : 'debit',
    );
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    final message = widget.isIncome
        ? (_isEditing ? l.incomeUpdated : l.incomeAdded)
        : (_isEditing ? l.expenseUpdated : l.expenseAdded);
    showAppSnack(context, message);
    Navigator.pop(context);

    // Saved locally at once; the cloud copy syncs in the background
    try {
      if (_isEditing) {
        await expenseProvider.updateExpense(entry);
      } else {
        await expenseProvider.addExpense(entry);
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  String? _validateAmount(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) return l.pleaseEnterAmount;
    final amount = AppFormat.parseAmount(value);
    if (amount == null || amount <= 0) return l.pleaseEnterValidAmount;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final income = widget.isIncome;
    final accent = income ? palette.income : palette.expense;

    final title = _isEditing
        ? l.edit
        : (income ? l.addIncomeTitle : l.addExpenseTitle);
    final submitLabel = income
        ? (_isEditing ? l.updateIncome : l.saveIncome)
        : (_isEditing ? l.updateExpense : l.saveExpense);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            AmountField(
              controller: _amountController,
              label: l.amount,
              color: accent,
              autofocus: !_isEditing,
              validator: _validateAmount,
            ),
            const SizedBox(height: 24),
            if (income)
              IncomeCategoryDropdown(
                selectedCategory: _category,
                labelText: l.incomeCategory,
                prefixIcon: Icons.trending_up_rounded,
                onChanged: (value) => setState(() => _category = value!),
              )
            else
              GroupedCategoryDropdown(
                selectedCategory: _category,
                labelText: l.category,
                prefixIcon: Icons.category_rounded,
                onChanged: (value) => setState(() => _category = value!),
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.titleOptional,
                hintText: income ? l.incomeTitleHint : l.titleHint,
                prefixIcon: const Icon(Icons.short_text_rounded),
              ),
            ),
            const SizedBox(height: 14),
            PickerField(
              label: l.date,
              value: AppFormat.date(context, _date),
              icon: Icons.calendar_today_rounded,
              onTap: _pickDate,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.noteOptional,
                hintText: l.noteHint,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 28),
            SubmitButton(
              label: submitLabel,
              icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
              color: accent,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
