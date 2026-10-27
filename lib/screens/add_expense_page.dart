import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import 'transaction_form.dart';

class AddExpensePage extends StatelessWidget {
  final Expense? expense; // For editing existing expense

  const AddExpensePage({super.key, this.expense});

  @override
  Widget build(BuildContext context) =>
      TransactionForm(isIncome: false, existing: expense);
}
