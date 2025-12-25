import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/hive_service.dart';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  DateTime _selectedMonth = DateTime.now();
  final bool _autoSync = true; // Always auto-backup to Firestore
  DateTime? _lastBackupTime; // Track last backup time
  final FirestoreService _firestoreService =
      FirestoreService(); // Firestore service
  final AuthService _authService = AuthService();
  String? _currentUserId; // Track current user to detect switches

  List<Expense> get expenses => _expenses;
  DateTime get selectedMonth => _selectedMonth;
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

    // Try to restore from Firestore backup for new user (was Google Drive)
    if (_expenses.isEmpty) {
      print('No local data found, attempting Firestore restore...');
      final restored = await restoreFromFirestore();
      if (restored) {
        print('✅ Data restored from Firestore backup');
      } else {
        print('No Firestore backup found for this user');
      }
    } else {
      // If user has local data, backup to Firestore immediately
      print(
          '📤 Local data found (${_expenses.length} expenses), backing up to Firestore...');
      final backed = await backupToFirestore();
      if (backed) {
        print('✅ Local data backed up to Firestore successfully');
      } else {
        print('⚠️ Failed to backup local data to Firestore');
      }
    }

    print(
        '✅ ExpenseProvider: Expenses reloaded for new user (${_expenses.length} expenses)');
  }

  // Load last backup time on initialization
  Future<void> _loadLastBackupTime() async {
    try {
      _lastBackupTime = await _firestoreService
          .getLastBackupTime(); // Changed from _driveService to _firestoreService
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

    // Auto-backup to Firestore if enabled (in background) - was Google Drive
    if (_autoSync) {
      try {
        print('🚀 [EXPENSE_PROVIDER] Attempting Firestore backup...');
        print('🚀 [EXPENSE_PROVIDER] Auto-sync enabled: $_autoSync');
        print(
            '🚀 [EXPENSE_PROVIDER] Total expenses to backup: ${_expenses.length}');
        print(
            '🚀 [EXPENSE_PROVIDER] Current user: ${_authService.getUserEmail()}');

        final monthlyBudget = HiveService.getMonthlyBudget();
        print('🚀 [EXPENSE_PROVIDER] Monthly budget: $monthlyBudget');

        // First attempt backup to Firestore
        print('🚀 [EXPENSE_PROVIDER] Starting first backup attempt...');
        bool success = await _firestoreService.backupExpenses(_expenses,
            monthlyBudget: monthlyBudget);

        // If backup fails, try to ensure Firestore is ready and retry once
        if (!success) {
          print(
              '⚠️ [EXPENSE_PROVIDER] Initial backup failed, ensuring Firestore readiness and retrying...');
          final firestoreReady =
              await _firestoreService.ensureFirestoreReadyAfterDeletion();
          if (firestoreReady) {
            print(
                '🚀 [EXPENSE_PROVIDER] Firestore is ready, attempting second backup...');
            success = await _firestoreService.backupExpenses(_expenses,
                monthlyBudget: monthlyBudget);
          } else {
            print(
                '❌ [EXPENSE_PROVIDER] Failed to prepare Firestore for backup');
          }
        }

        if (success) {
          print('✅ [EXPENSE_PROVIDER] Auto-backup to Firestore successful');
          _lastBackupTime = DateTime.now();
          notifyListeners(); // Update UI with new backup time
        } else {
          print(
              '⚠️ [EXPENSE_PROVIDER] Auto-backup to Firestore failed after retry');
        }
      } catch (e, stackTrace) {
        print('❌ [EXPENSE_PROVIDER] Failed to backup to Firestore: $e');
        print('❌ [EXPENSE_PROVIDER] Stack trace: $stackTrace');
      }
    } else {
      print('⚠️ [EXPENSE_PROVIDER] Auto-sync is disabled, skipping backup');
    }
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    await HiveService.updateExpense(expense);

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    // Auto-backup to Firestore if enabled (in background) - was Google Drive
    if (_autoSync) {
      try {
        print('Attempting Firestore backup after update...');
        final monthlyBudget = HiveService.getMonthlyBudget();

        // First attempt backup to Firestore
        bool success = await _firestoreService.backupExpenses(_expenses,
            monthlyBudget: monthlyBudget);

        // If backup fails, try to ensure Firestore is ready and retry once
        if (!success) {
          print(
              '⚠️ Initial backup failed, ensuring Firestore readiness and retrying...');
          final firestoreReady =
              await _firestoreService.ensureFirestoreReadyAfterDeletion();
          if (firestoreReady) {
            success = await _firestoreService.backupExpenses(_expenses,
                monthlyBudget: monthlyBudget);
          }
        }

        if (success) {
          print('✅ Auto-backup to Firestore successful');
          _lastBackupTime = DateTime.now();
          notifyListeners(); // Update UI with new backup time
        } else {
          print('⚠️ Auto-backup to Firestore failed after retry');
        }
      } catch (e) {
        print('❌ Failed to backup to Firestore: $e');
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

    // Auto-backup to Firestore if enabled (in background) - was Google Drive
    if (_autoSync) {
      try {
        final monthlyBudget = HiveService.getMonthlyBudget();

        // First attempt backup to Firestore
        bool success = await _firestoreService.backupExpenses(_expenses,
            monthlyBudget: monthlyBudget);

        // If backup fails, try to ensure Firestore is ready and retry once
        if (!success) {
          print(
              '⚠️ Initial backup failed, ensuring Firestore readiness and retrying...');
          final firestoreReady =
              await _firestoreService.ensureFirestoreReadyAfterDeletion();
          if (firestoreReady) {
            success = await _firestoreService.backupExpenses(_expenses,
                monthlyBudget: monthlyBudget);
          }
        }

        if (success) {
          print('✅ Auto-backup to Firestore successful after delete');
          _lastBackupTime = DateTime.now();
          notifyListeners(); // Update UI with new backup time
        } else {
          print('⚠️ Auto-backup to Firestore failed after retry');
        }
      } catch (e) {
        print('❌ Failed to backup to Firestore: $e');
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

  // Permanently delete all data including Firestore backups - FAST (3 seconds max) - was Google Drive
  Future<bool> permanentlyDeleteAllData() async {
    try {
      print('Starting FAST permanent deletion of all data...');
      final stopwatch = Stopwatch()..start();

      // Step 1: Clear local data immediately (fastest operation)
      await HiveService.clearAllData();
      // Also reset monthly budget to default
      await HiveService.setMonthlyBudget(10000.0);
      print(
          '✅ Local data cleared and budget reset (${stopwatch.elapsedMilliseconds}ms)');

      // Step 2: Delete Firestore backups with timeout (was Google Drive)
      final firestoreDeleteSuccess =
          await _firestoreService.deleteAllBackupFiles().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print('⚠️ Firestore deletion timed out - continuing in background');
          // Continue deletion in background
          _firestoreService.deleteAllBackupFiles().catchError((e) {
            print('Background Firestore deletion failed: $e');
            return false;
          });
          return false;
        },
      ).catchError((e) {
        print('Firestore deletion error: $e');
        return false;
      });

      print(
          '✅ Cloud operations completed (${stopwatch.elapsedMilliseconds}ms)');

      // Step 3: Ensure Firestore is ready for future backups
      if (firestoreDeleteSuccess) {
        // Prepare Firestore for new backups after deletion
        _firestoreService.ensureFirestoreReadyAfterDeletion().catchError((e) {
          print('Failed to prepare Firestore for future backups: $e');
          return false;
        });
      }

      // Step 4: Immediate UI updates
      _lastBackupTime = null;
      loadExpenses(); // This will show empty list immediately

      stopwatch.stop();

      if (firestoreDeleteSuccess) {
        print(
            '✅ PERMANENT deletion completed successfully in ${stopwatch.elapsedMilliseconds}ms - NO RECOVERY POSSIBLE');
      } else {
        print(
            '⚠️ PARTIAL deletion completed in ${stopwatch.elapsedMilliseconds}ms - Firestore backups may still exist');
      }

      // Return true only if BOTH local AND Firestore deletion succeeded
      return firestoreDeleteSuccess;
    } catch (e) {
      print('❌ Error during FAST permanent deletion: $e');
      return false;
    }
  }

  // Note: Firestore is used for both authentication and expense data storage

  // Manual backup to Firestore (was Google Drive)
  Future<bool> backupToFirestore() async {
    try {
      final monthlyBudget = HiveService.getMonthlyBudget();

      // First attempt backup
      bool success = await _firestoreService.backupExpenses(_expenses,
          monthlyBudget: monthlyBudget);

      // If backup fails, try to ensure Firestore is ready and retry once
      if (!success) {
        print(
            '⚠️ Manual backup failed, ensuring Firestore readiness and retrying...');
        final firestoreReady =
            await _firestoreService.ensureFirestoreReadyAfterDeletion();
        if (firestoreReady) {
          success = await _firestoreService.backupExpenses(_expenses,
              monthlyBudget: monthlyBudget);
        }
      }

      if (success) {
        _lastBackupTime = DateTime.now();
        notifyListeners(); // Update UI with new backup time
      }
      return success;
    } catch (e) {
      print('Failed to backup to Firestore: $e');
      return false;
    }
  }

  // Restore from Firestore (automatic restore after sign-in) - was Google Drive
  // Note: After calling this, you should call budgetProvider.reloadBudget() to update the UI
  Future<bool> restoreFromFirestore() async {
    try {
      final restoreData = await _firestoreService.restoreExpenses();
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
          // Note: BudgetProvider needs to reload to see this change
        }

        return true;
      }
      print('ℹ️ No backup data found to restore');
      return false;
    } catch (e) {
      print('❌ Failed to restore from Firestore: $e');
      return false;
    }
  }

  // Get last backup time from Firestore
  Future<DateTime?> getLastBackupTime() async {
    try {
      return await _firestoreService.getLastBackupTime();
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

  // Debug method to test Firestore backup manually
  Future<bool> testFirestoreBackup() async {
    try {
      print('🧪 [DEBUG] Testing Firestore backup manually...');
      print('🧪 [DEBUG] Current expenses count: ${_expenses.length}');
      print('🧪 [DEBUG] Auto-sync enabled: $_autoSync');
      print('🧪 [DEBUG] User email: ${_authService.getUserEmail()}');
      print('🧪 [DEBUG] User ID: ${_authService.getUserId()}');

      final monthlyBudget = HiveService.getMonthlyBudget();
      print('🧪 [DEBUG] Monthly budget: $monthlyBudget');

      // Try direct backup
      final success = await _firestoreService.backupExpenses(_expenses,
          monthlyBudget: monthlyBudget);

      if (success) {
        print('✅ [DEBUG] Manual backup test successful!');
        _lastBackupTime = DateTime.now();
        notifyListeners();
      } else {
        print('❌ [DEBUG] Manual backup test failed!');
      }

      return success;
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Manual backup test error: $e');
      print('❌ [DEBUG] Stack trace: $stackTrace');
      return false;
    }
  }
}
