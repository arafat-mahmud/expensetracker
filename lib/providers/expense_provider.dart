import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/hive_service.dart';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/sync_queue_service.dart';
import '../services/collection_sync.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  DateTime _selectedMonth = DateTime.now();
  final bool _autoSync = true; // Always auto-backup to Firestore
  DateTime? _lastBackupTime; // Track last backup time
  final FirestoreService _firestoreService =
      FirestoreService(); // Firestore service
  final AuthService _authService = AuthService();
  String? _currentUserId; // Track current user to detect switches

  // Keeps expenses (and the budget) in step across the user's devices
  late final CollectionSync _cloudSync = CollectionSync(
    scope: 'expenses',
    entity: 'expense',
    collection: _firestoreService.getUserExpensesCollection,
    isLocalEmpty: () => HiveService.getExpenseBox().isEmpty,
    apply: _applyRemoteChanges,
    onInitialLoad: _restoreLegacyBudget,
  );

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
    _cloudSync.stop();
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
    _cloudSync.stop();
    loadExpenses();

    // Load the user's cloud data if needed and listen for changes from their
    // other devices. Local data needs no re-upload: every change was already
    // queued as a single-document write when it was made.
    final restored = await startCloudSync();
    if (restored) {
      print('✅ Data restored from Firestore backup');
    }

    print(
        '✅ ExpenseProvider: Expenses reloaded for new user (${_expenses.length} expenses)');
  }

  // Load all expenses from Hive
  void loadExpenses() {
    _expenses = HiveService.getAllExpenses();
    // Sort by date (newest first)
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // Add new expense (exactly one Firestore write, via the sync queue)
  Future<void> addExpense(Expense expense) async {
    await HiveService.addExpense(expense);

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    if (_autoSync) {
      await SyncQueueService().enqueueExpenseUpsert(expense, isNew: true);
    }
  }

  // Update expense (exactly one Firestore write, via the sync queue)
  Future<void> updateExpense(Expense expense) async {
    await HiveService.updateExpense(expense);

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    if (_autoSync) {
      await SyncQueueService().enqueueExpenseUpsert(expense);
    }
  }

  // Delete expense (one Firestore delete, via the sync queue so it also
  // works offline without blocking the UI)
  Future<void> deleteExpense(String id) async {
    // Delete from local storage first
    await HiveService.deleteExpense(id);

    if (_autoSync) {
      await SyncQueueService().enqueueExpenseDelete(id);
    }

    // Immediately update UI
    _expenses = HiveService.getAllExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
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

      // Step 1: Clear local data immediately (fastest operation).
      // Queued writes are dropped too; those docs are about to be deleted.
      await SyncQueueService().discardPendingOps('expense');
      await HiveService.clearAllData();
      // Also reset monthly budget to default
      await HiveService.setMonthlyBudget(10000.0);
      print(
          '✅ Local data cleared and budget reset (${stopwatch.elapsedMilliseconds}ms)');

      // Step 2: Delete Firestore backups with timeout (was Google Drive).
      // The ids come from Firestore's local cache plus a delta query, so
      // listing them costs about one read instead of one per document.
      Future<bool> deleteFromCloud() async => _firestoreService
          .deleteAllBackupFiles(await _cloudSync.allDocIds());
      final firestoreDeleteSuccess = await deleteFromCloud().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // The original deletion keeps running in the background. Starting
          // a second one would read and delete every document again.
          print('⚠️ Firestore deletion timed out - continuing in background');
          return false;
        },
      ).catchError((e) {
        print('Firestore deletion error: $e');
        return false;
      });

      print(
          '✅ Cloud operations completed (${stopwatch.elapsedMilliseconds}ms)');

      // Step 3: Immediate UI updates
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

  // Manual backup to Firestore (forces immediate sync)
  // Rewrites every expense (one write each), so it is never called automatically
  Future<bool> backupToFirestore() async {
    try {
      await SyncQueueService().flushPendingOps();

      final monthlyBudget = HiveService.getMonthlyBudget();

      // Force immediate backup
      final success = await _firestoreService.backupExpenses(
        _expenses,
        monthlyBudget: monthlyBudget,
        force: true,
      );

      if (success) {
        _lastBackupTime = DateTime.now();
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Failed to backup to Firestore: $e');
      return false;
    }
  }

  /// Loads the user's cloud data if this device needs it, then keeps
  /// listening for changes made on their other devices (see CollectionSync).
  /// Cheap to call again, e.g. from pull-to-refresh: while the listener is
  /// running it costs nothing.
  /// Returns true when saved expenses were loaded into an empty local store.
  Future<bool> startCloudSync() async {
    final loaded = await _cloudSync.start();
    return loaded && _expenses.isNotEmpty;
  }

  Future<void> _applyRemoteChanges(RemoteChanges changes) async {
    if (changes.wiped) {
      // "Delete All" on another device; keep only writes still queued here
      final pending = SyncQueueService().pendingDocIds(['expense']);
      final box = HiveService.getExpenseBox();
      await box.deleteAll(
          box.keys.where((id) => !pending.contains(id.toString())).toList());
      await HiveService.setMonthlyBudget(10000.0); // same reset as there
    }

    final settings = changes.upserts.remove(CollectionSync.settingsDocId);
    if (settings != null) {
      final budget = (settings['monthlyBudget'] as num?)?.toDouble();
      if (budget != null) await HiveService.setMonthlyBudget(budget);
      final userId = _authService.getUserId();
      if (userId != null) await HiveService.setRestoreDone('budget', userId);
    }

    await HiveService.applyRemote(
      HiveService.getExpenseBox(),
      parseRemoteDocs(changes.upserts, Expense.fromJson),
      changes.deletedIds,
    );
    loadExpenses();
  }

  // Budgets saved before cloud sync existed live on the user doc. Read it at
  // most once per sign-in, and only if the synced `_settings` doc had none.
  Future<void> _restoreLegacyBudget() async {
    final userId = _authService.getUserId();
    if (userId == null || HiveService.isRestoreDone('budget', userId)) return;

    final settings = await _firestoreService.getSettings();
    final budget = (settings?['monthlyBudget'] as num?)?.toDouble();
    if (budget != null) {
      await HiveService.setMonthlyBudget(budget);
      print('✅ Monthly budget restored: $budget');
    }
    await HiveService.setRestoreDone('budget', userId);
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
