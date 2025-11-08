import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../services/google_drive_service.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  DateTime _selectedMonth = DateTime.now();
  bool _autoSync = true; // Auto-sync to cloud
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleDriveService _driveService = GoogleDriveService();

  List<Expense> get expenses => _expenses;
  DateTime get selectedMonth => _selectedMonth;
  bool get autoSync => _autoSync;

  // Get only debit transactions (expenses)
  List<Expense> get debits => _expenses.where((e) => e.isDebit).toList();

  // Get only credit transactions (income)
  List<Expense> get credits => _expenses.where((e) => e.isCredit).toList();

  // Get current balance (total credits - total debits)
  double get currentBalance {
    final totalCredits = credits.fold(0.0, (sum, e) => sum + e.amount);
    final totalDebits = debits.fold(0.0, (sum, e) => sum + e.amount);
    return totalCredits - totalDebits;
  }

  ExpenseProvider() {
    loadExpenses();
  }

  // Load all expenses from Hive
  void loadExpenses() {
    _expenses = HiveService.getAllExpenses();
    // Sort by date (newest first)
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // Add new expense
  Future<void> addExpense(Expense expense) async {
    await HiveService.addExpense(expense);

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // Auto-sync to cloud if enabled (in background)
    if (_autoSync) {
      try {
        await _firestoreService.syncExpense(expense);
        print('Synced to Firestore');
      } catch (e) {
        print('Failed to sync to Firestore: $e');
      }

      // Auto-backup to Google Drive
      try {
        print('Attempting Google Drive backup...');
        final success = await _driveService.backupExpenses(_expenses);
        if (success) {
          print('✅ Auto-backup to Google Drive successful');
        } else {
          print('⚠️ Auto-backup to Google Drive failed');
        }
      } catch (e) {
        print('❌ Failed to backup to Google Drive: $e');
      }
    }
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    await HiveService.updateExpense(expense);

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // Auto-sync to cloud if enabled (in background)
    if (_autoSync) {
      try {
        await _firestoreService.syncExpense(expense);
        print('Synced to Firestore');
      } catch (e) {
        print('Failed to sync to Firestore: $e');
      }

      // Auto-backup to Google Drive
      try {
        print('Attempting Google Drive backup after update...');
        final success = await _driveService.backupExpenses(_expenses);
        if (success) {
          print('✅ Auto-backup to Google Drive successful');
        } else {
          print('⚠️ Auto-backup to Google Drive failed');
        }
      } catch (e) {
        print('❌ Failed to backup to Google Drive: $e');
      }
    }
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    await HiveService.deleteExpense(id);

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // Auto-sync to cloud if enabled (in background)
    if (_autoSync) {
      try {
        await _firestoreService.deleteExpense(id);
      } catch (e) {
        print('Failed to delete from Firestore: $e');
      }

      // Auto-backup to Google Drive
      try {
        await _driveService.backupExpenses(_expenses);
        print('Auto-backup to Google Drive successful after delete');
      } catch (e) {
        print('Failed to backup to Google Drive: $e');
      }
    }
  }

  // Get total expense for a specific month
  double getTotalExpenseForMonth(DateTime month) {
    return _expenses
        .where((expense) =>
            expense.date.year == month.year &&
            expense.date.month == month.month &&
            expense.isDebit)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get total income for a specific month
  double getTotalIncomeForMonth(DateTime month) {
    return _expenses
        .where((expense) =>
            expense.date.year == month.year &&
            expense.date.month == month.month &&
            expense.isCredit)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get balance for a specific month
  double getBalanceForMonth(DateTime month) {
    return getTotalIncomeForMonth(month) - getTotalExpenseForMonth(month);
  }

  // Get expenses for a specific month
  List<Expense> getExpensesForMonth(DateTime month) {
    return _expenses
        .where((expense) =>
            expense.date.year == month.year &&
            expense.date.month == month.month)
        .toList();
  }

  // Get category-wise expense for a month
  Map<String, double> getCategoryExpenseForMonth(DateTime month) {
    final monthExpenses =
        getExpensesForMonth(month).where((expense) => expense.isDebit).toList();
    final Map<String, double> categoryExpense = {};

    for (var expense in monthExpenses) {
      categoryExpense[expense.category] =
          (categoryExpense[expense.category] ?? 0) + expense.amount;
    }

    return categoryExpense;
  }

  // Get category-wise income for a month
  Map<String, double> getCategoryIncomeForMonth(DateTime month) {
    final monthIncomes = getExpensesForMonth(month)
        .where((expense) => expense.isCredit)
        .toList();
    final Map<String, double> categoryIncome = {};

    for (var income in monthIncomes) {
      categoryIncome[income.category] =
          (categoryIncome[income.category] ?? 0) + income.amount;
    }

    return categoryIncome;
  }

  // Get daily expenses for a month (for bar chart)
  Map<int, double> getDailyExpenseForMonth(DateTime month) {
    final monthExpenses =
        getExpensesForMonth(month).where((expense) => expense.isDebit).toList();
    final Map<int, double> dailyExpense = {};

    for (var expense in monthExpenses) {
      final day = expense.date.day;
      dailyExpense[day] = (dailyExpense[day] ?? 0) + expense.amount;
    }

    return dailyExpense;
  }

  // Get expenses by category
  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  // Get total expense for a category
  double getTotalExpenseForCategory(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Set selected month for filtering
  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Search expenses
  List<Expense> searchExpenses(String query) {
    return _expenses
        .where((expense) =>
            expense.title.toLowerCase().contains(query.toLowerCase()) ||
            expense.category.toLowerCase().contains(query.toLowerCase()) ||
            expense.note.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter expenses by date range
  List<Expense> filterByDateRange(DateTime start, DateTime end) {
    return _expenses
        .where((expense) =>
            expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // Clear all expenses
  Future<void> clearAllExpenses() async {
    await HiveService.clearAllData();

    // Also clear from cloud if auto-sync enabled
    if (_autoSync) {
      try {
        await _firestoreService.clearAllData();
      } catch (e) {
        print('Failed to clear Firestore data: $e');
      }
    }

    loadExpenses();
  }

  // Toggle auto-sync
  void toggleAutoSync(bool value) {
    _autoSync = value;
    notifyListeners();
  }

  // Manual sync all to Firestore
  Future<bool> syncToFirestore() async {
    try {
      await _firestoreService.syncAllExpenses(_expenses);
      return true;
    } catch (e) {
      print('Failed to sync to Firestore: $e');
      return false;
    }
  }

  // Manual backup to Google Drive
  Future<bool> backupToGoogleDrive() async {
    try {
      return await _driveService.backupExpenses(_expenses);
    } catch (e) {
      print('Failed to backup to Google Drive: $e');
      return false;
    }
  }

  // Restore from Google Drive
  Future<bool> restoreFromGoogleDrive() async {
    try {
      final expenses = await _driveService.restoreExpenses();
      if (expenses != null && expenses.isNotEmpty) {
        // Save to Hive
        for (var expense in expenses) {
          await HiveService.addExpense(expense);
        }
        loadExpenses();
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to restore from Google Drive: $e');
      return false;
    }
  }

  // Get last backup time from Google Drive
  Future<DateTime?> getLastBackupTime() async {
    try {
      return await _driveService.getLastBackupTime();
    } catch (e) {
      print('Failed to get last backup time: $e');
      return null;
    }
  }
}
