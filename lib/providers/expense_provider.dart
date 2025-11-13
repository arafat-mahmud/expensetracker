import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/hive_service.dart';
import '../services/google_drive_service.dart';
import '../services/auth_service.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  DateTime _selectedMonth = DateTime.now();
  bool _autoSync = true; // Auto-backup to Google Drive
  DateTime? _lastBackupTime; // Track last backup time
  final GoogleDriveService _driveService = GoogleDriveService();
  final AuthService _authService = AuthService();
  String? _currentUserId; // Track current user to detect switches

  List<Expense> get expenses => _expenses;
  DateTime get selectedMonth => _selectedMonth;
  bool get autoSync => _autoSync;
  DateTime? get lastBackupTime => _lastBackupTime;

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
    _currentUserId = _authService.getUserId();
    loadExpenses();
    _loadLastBackupTime();

    // Listen to auth state changes to detect user switches
    _authService.authStateChanges.listen((user) {
      final newUserId = user?.uid;
      if (_currentUserId != newUserId) {
        print(
            'ExpenseProvider: User switch detected from $_currentUserId to $newUserId');
        _currentUserId = newUserId;
        if (newUserId != null) {
          // New user signed in, reload data
          reloadForNewUser();
        } else {
          // User signed out, clear data
          _clearDataOnSignOut();
        }
      }
    });
  }

  // Clear data when user signs out
  void _clearDataOnSignOut() {
    print('ExpenseProvider: Clearing data on sign out');
    _expenses = [];
    _lastBackupTime = null;
    _selectedMonth = DateTime.now();
    notifyListeners();
  }

  // Reload expenses for a new user (called after user switch)
  Future<void> reloadForNewUser() async {
    print('🔄 ExpenseProvider: Reloading expenses for new user...');

    // Clear current data first
    _expenses = [];
    _lastBackupTime = null;
    _selectedMonth = DateTime.now();
    notifyListeners(); // Immediately show empty state

    // Load new user's data
    loadExpenses();
    await _loadLastBackupTime();

    // Try to restore from Google Drive backup for new user
    if (_expenses.isEmpty) {
      print('No local data found, attempting Google Drive restore...');
      final restored = await restoreFromGoogleDrive();
      if (restored) {
        print('✅ Data restored from Google Drive backup');
      } else {
        print('No Google Drive backup found for this user');
      }
    }

    print(
        '✅ ExpenseProvider: Expenses reloaded for new user (${_expenses.length} expenses)');
  }

  // Load last backup time on initialization
  Future<void> _loadLastBackupTime() async {
    try {
      _lastBackupTime = await _driveService.getLastBackupTime();
      notifyListeners();
    } catch (e) {
      print('Failed to load last backup time: $e');
    }
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

    // Auto-backup to Google Drive if enabled (in background)
    if (_autoSync) {
      try {
        print('Attempting Google Drive backup...');
        final monthlyBudget = HiveService.getMonthlyBudget();
        final success = await _driveService.backupExpenses(_expenses,
            monthlyBudget: monthlyBudget);
        if (success) {
          print('✅ Auto-backup to Google Drive successful');
          _lastBackupTime = DateTime.now();
          notifyListeners(); // Update UI with new backup time
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

    // Auto-backup to Google Drive if enabled (in background)
    if (_autoSync) {
      try {
        print('Attempting Google Drive backup after update...');
        final monthlyBudget = HiveService.getMonthlyBudget();
        final success = await _driveService.backupExpenses(_expenses,
            monthlyBudget: monthlyBudget);
        if (success) {
          print('✅ Auto-backup to Google Drive successful');
          _lastBackupTime = DateTime.now();
          notifyListeners(); // Update UI with new backup time
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

    // Auto-backup to Google Drive if enabled (in background)
    if (_autoSync) {
      try {
        final monthlyBudget = HiveService.getMonthlyBudget();
        final success = await _driveService.backupExpenses(_expenses,
            monthlyBudget: monthlyBudget);
        if (success) {
          print('Auto-backup to Google Drive successful after delete');
          _lastBackupTime = DateTime.now();
          notifyListeners(); // Update UI with new backup time
        }
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

  // Get daily expenses for the last N days
  Map<int, double> getDailyExpenseForLastNDays(int days) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final startDate = today.subtract(Duration(days: days - 1));
    final Map<int, double> dailyExpense = {};

    for (int i = 0; i < days; i++) {
      dailyExpense[i + 1] = 0.0;
    }

    final recentExpenses = _expenses.where((expense) {
      final expenseDate =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      return expense.isDebit &&
          (expenseDate.isAtSameMomentAs(startDate) ||
              expenseDate.isAfter(startDate)) &&
          (expenseDate.isAtSameMomentAs(today) || expenseDate.isBefore(today));
    });

    for (var expense in recentExpenses) {
      final expenseDate =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      final dayIndex = expenseDate.difference(startDate).inDays + 1;
      if (dayIndex > 0 && dayIndex <= days) {
        dailyExpense[dayIndex] = (dailyExpense[dayIndex] ?? 0) + expense.amount;
      }
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

  // Clear all expenses (local only - keeps Google Drive backups intact)
  Future<void> clearAllExpenses() async {
    await HiveService.clearAllData();
    loadExpenses();
  }

  // Permanently delete all data including Google Drive backups - FAST (3 seconds max)
  Future<bool> permanentlyDeleteAllData() async {
    try {
      print('Starting FAST permanent deletion of all data...');
      final stopwatch = Stopwatch()..start();

      // Step 1: Clear local data immediately (fastest operation)
      await HiveService.clearAllData();
      print('✅ Local data cleared (${stopwatch.elapsedMilliseconds}ms)');

      // Step 2: Delete Google Drive backups with timeout
      final driveDeleteSuccess =
          await _driveService.deleteAllBackupFiles().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print(
              '⚠️ Google Drive deletion timed out - continuing in background');
          // Continue deletion in background
          _driveService.deleteAllBackupFiles().catchError((e) {
            print('Background Google Drive deletion failed: $e');
            return false;
          });
          return false;
        },
      ).catchError((e) {
        print('Google Drive deletion error: $e');
        return false;
      });

      print(
          '✅ Cloud operations completed (${stopwatch.elapsedMilliseconds}ms)');

      // Step 3: Immediate UI updates
      _lastBackupTime = null;
      loadExpenses(); // This will show empty list immediately

      stopwatch.stop();

      if (driveDeleteSuccess) {
        print(
            '✅ PERMANENT deletion completed successfully in ${stopwatch.elapsedMilliseconds}ms - NO RECOVERY POSSIBLE');
      } else {
        print(
            '⚠️ PARTIAL deletion completed in ${stopwatch.elapsedMilliseconds}ms - Google Drive backups may still exist');
      }

      // Return true only if BOTH local AND Google Drive deletion succeeded
      return driveDeleteSuccess;
    } catch (e) {
      print('❌ Error during FAST permanent deletion: $e');
      return false;
    }
  }

  // Toggle auto-sync
  void toggleAutoSync(bool value) {
    _autoSync = value;
    notifyListeners();
  }

  // Note: Firestore is only used for authentication, not for expense data storage

  // Manual backup to Google Drive
  Future<bool> backupToGoogleDrive() async {
    try {
      final monthlyBudget = HiveService.getMonthlyBudget();
      final success = await _driveService.backupExpenses(_expenses,
          monthlyBudget: monthlyBudget);
      if (success) {
        _lastBackupTime = DateTime.now();
        notifyListeners(); // Update UI with new backup time
      }
      return success;
    } catch (e) {
      print('Failed to backup to Google Drive: $e');
      return false;
    }
  }

  // Restore from Google Drive (automatic restore after sign-in)
  Future<bool> restoreFromGoogleDrive() async {
    try {
      final restoreData = await _driveService.restoreExpenses();
      if (restoreData != null) {
        final expenses = restoreData['expenses'] as List<Expense>?;
        final monthlyBudget = restoreData['monthlyBudget'] as double?;

        if (expenses != null && expenses.isNotEmpty) {
          // Clear existing local data first
          await HiveService.clearAllData();

          // Save restored data to Hive
          for (var expense in expenses) {
            await HiveService.addExpense(expense);
          }
          loadExpenses();
          print(
              '✅ Automatic restore successful: ${expenses.length} expenses restored');
        }

        // Restore monthly budget if available
        if (monthlyBudget != null) {
          await HiveService.setMonthlyBudget(monthlyBudget);
          print('✅ Monthly budget restored: $monthlyBudget');
        }

        return true;
      }
      print('ℹ️ No backup data found to restore');
      return false;
    } catch (e) {
      print('❌ Failed to restore from Google Drive: $e');
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

  // Debug method to get current user context
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentUserId': _currentUserId,
      'authServiceUserId': _authService.getUserId(),
      'expenseCount': _expenses.length,
      'selectedMonth': _selectedMonth.toString(),
      'autoSync': _autoSync,
      'lastBackupTime': _lastBackupTime?.toString(),
    };
  }
}
