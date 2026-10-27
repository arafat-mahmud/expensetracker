import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import 'transaction_form.dart';

class AddIncomePage extends StatelessWidget {
  final Expense? income; // For editing existing income

  const AddIncomePage({super.key, this.income});

  @override
  Widget build(BuildContext context) =>
      TransactionForm(isIncome: true, existing: income);
}
