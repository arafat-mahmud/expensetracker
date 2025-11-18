import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get user's expenses collection
  CollectionReference _getUserExpensesCollection() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  // NEW: Get date-wise expense document path (date as document, expense ID as subdocument)
  // Format: users/{userId}/expenses_by_date/{YYYY-MM-DD}/{expenseId}
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  CollectionReference _getExpensesByDateCollection() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses_by_date');
  }

  DocumentReference _getDateDocument(DateTime date) {
    return _getExpensesByDateCollection().doc(_getDateKey(date));
  }

  CollectionReference _getExpensesForDate(DateTime date) {
    return _getDateDocument(date).collection('items');
  }

  // Get user's settings document
  DocumentReference _getUserSettingsDocument() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId);
  }

  // Sync expense to Firestore
  // Now syncs to BOTH flat and date-wise structures
  Future<void> syncExpense(Expense expense) async {
    try {
      // Sync to flat structure (existing)
      await _getUserExpensesCollection().doc(expense.id).set(expense.toJson());

      // Sync to date-wise structure (NEW)
      await syncExpenseByDate(expense);
    } catch (e) {
      print('Error syncing expense to Firestore: $e');
      rethrow;
    }
  }

  // Sync all expenses to Firestore
  // Now syncs to BOTH flat and date-wise structures
  Future<void> syncAllExpenses(List<Expense> expenses) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserExpensesCollection();

      for (var expense in expenses) {
        batch.set(collection.doc(expense.id), expense.toJson());
      }

      await batch.commit();

      // Also sync to date-wise structure
      await syncAllExpensesByDate(expenses);
    } catch (e) {
      print('Error syncing all expenses to Firestore: $e');
      rethrow;
    }
  }

  // Delete expense from Firestore
  // Now deletes from BOTH structures
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Delete from flat structure
      await _getUserExpensesCollection().doc(expenseId).delete();

      // Note: For date-wise structure, we need the full expense object to know the date
      // The deleteExpenseByDate method should be called separately with the expense object
    } catch (e) {
      print('Error deleting expense from Firestore: $e');
      rethrow;
    }
  }

  // Get all expenses from Firestore
  Future<List<Expense>> getAllExpenses() async {
    try {
      final snapshot = await _getUserExpensesCollection().get();
      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting expenses from Firestore: $e');
      return [];
    }
  }

  // Stream of expenses (real-time)
  Stream<List<Expense>> expensesStream() {
    return _getUserExpensesCollection().snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Sync settings to Firestore
  Future<void> syncSettings(double monthlyBudget, bool isDarkMode) async {
    try {
      await _getUserSettingsDocument().set({
        'monthlyBudget': monthlyBudget,
        'isDarkMode': isDarkMode,
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing settings to Firestore: $e');
      rethrow;
    }
  }

  // Get settings from Firestore
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final doc = await _getUserSettingsDocument().get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting settings from Firestore: $e');
      return null;
    }
  }

  // Clear all user data from Firestore
  Future<void> clearAllData() async {
    try {
      final collection = _getUserExpensesCollection();
      final snapshot = await collection.get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing data from Firestore: $e');
      rethrow;
    }
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final doc = await _getUserSettingsDocument().get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['lastSynced'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  // ========== NEW BACKUP & RESTORE METHODS (replacing Google Drive) ==========

  // Backup expenses to Firestore (replacement for Google Drive backup)
  // Now supports BOTH flat structure AND date-wise organization
  Future<bool> backupExpenses(List<Expense> expenses,
      {double? monthlyBudget}) async {
    try {
      print(
          '💾 [FIRESTORE_BACKUP] Starting Firestore backup for ${expenses.length} expenses...');
      print('💾 [FIRESTORE_BACKUP] User ID: ${_authService.getUserId()}');
      print('💾 [FIRESTORE_BACKUP] User email: ${_authService.getUserEmail()}');
      print('💾 [FIRESTORE_BACKUP] Monthly budget: $monthlyBudget');

      // Sync to BOTH structures for compatibility
      // 1. Flat structure (existing): users/{userId}/expenses/{expenseId}
      await syncAllExpenses(expenses);
      print('✅ [FIRESTORE_BACKUP] Synced to flat structure');

      // 2. Date-wise structure (NEW): users/{userId}/expenses_by_date/{date}/items/{expenseId}
      await syncAllExpensesByDate(expenses);
      print('✅ [FIRESTORE_BACKUP] Synced to date-wise structure');

      // Save backup metadata and settings
      await _getUserSettingsDocument().set({
        'monthlyBudget': monthlyBudget,
        'lastBackupTime': FieldValue.serverTimestamp(),
        'backupDate': DateTime.now().toIso8601String(),
        'userId': _authService.getUserId(),
        'userEmail': _authService.getUserEmail(),
        'expensesCount': expenses.length,
        'usesDateWiseStructure': true, // Flag to indicate date-wise support
      }, SetOptions(merge: true));

      print(
          '✅ [FIRESTORE_BACKUP] Backup completed successfully! ${expenses.length} expenses backed up to both structures');
      return true;
    } catch (e, stackTrace) {
      print('❌ [FIRESTORE_BACKUP] Error backing up to Firestore: $e');
      print('❌ [FIRESTORE_BACKUP] Stack trace: $stackTrace');
      return false;
    }
  }

  // Restore expenses from Firestore (replacement for Google Drive restore)
  // Now tries date-wise structure first, falls back to flat structure
  Future<Map<String, dynamic>?> restoreExpenses() async {
    try {
      print('📥 [FIRESTORE_RESTORE] Starting Firestore restore...');

      List<Expense> expenses = [];

      // Check which structure to use
      final settings = await getSettings();
      final usesDateWise = settings?['usesDateWiseStructure'] as bool? ?? false;

      if (usesDateWise) {
        // Try date-wise structure first (NEW)
        print('📥 [FIRESTORE_RESTORE] Using date-wise structure...');
        expenses = await getAllExpensesByDate();

        // If empty, fallback to flat structure
        if (expenses.isEmpty) {
          print(
              '📥 [FIRESTORE_RESTORE] Date-wise empty, trying flat structure...');
          expenses = await getAllExpenses();
        }
      } else {
        // Use flat structure (existing)
        print('📥 [FIRESTORE_RESTORE] Using flat structure...');
        expenses = await getAllExpenses();
      }

      final monthlyBudget = settings?['monthlyBudget'] as double?;

      if (expenses.isEmpty && monthlyBudget == null) {
        print('ℹ️ [FIRESTORE_RESTORE] No backup data found');
        return null;
      }

      print(
          '✅ [FIRESTORE_RESTORE] Restore successful: ${expenses.length} expenses, budget: $monthlyBudget');
      return {
        'expenses': expenses,
        'monthlyBudget': monthlyBudget,
      };
    } catch (e, stackTrace) {
      print('❌ [FIRESTORE_RESTORE] Error restoring from Firestore: $e');
      print('❌ [FIRESTORE_RESTORE] Stack trace: $stackTrace');
      return null;
    }
  }

  // Get last backup time from Firestore
  Future<DateTime?> getLastBackupTime() async {
    try {
      final doc = await _getUserSettingsDocument().get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['lastBackupTime'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      print('Error getting last backup time from Firestore: $e');
      return null;
    }
  }

  // Delete all backup data from Firestore (replacement for Google Drive delete)
  // Now deletes from BOTH structures
  Future<bool> deleteAllBackupFiles() async {
    try {
      print(
          '🗑️ [FIRESTORE_DELETE] Starting deletion of all backup data from Firestore...');
      final stopwatch = Stopwatch()..start();

      // Clear flat structure expenses
      await clearAllData();
      print('✅ [FIRESTORE_DELETE] Cleared flat structure');

      // Clear date-wise structure expenses
      await clearAllExpensesByDate();
      print('✅ [FIRESTORE_DELETE] Cleared date-wise structure');

      // Clear settings document (but keep the document itself)
      await _getUserSettingsDocument().set({
        'deletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      stopwatch.stop();
      print(
          '✅ [FIRESTORE_DELETE] Deletion completed in ${stopwatch.elapsedMilliseconds}ms');
      return true;
    } catch (e, stackTrace) {
      print('❌ [FIRESTORE_DELETE] Error deleting from Firestore: $e');
      print('❌ [FIRESTORE_DELETE] Stack trace: $stackTrace');
      return false;
    }
  }

  // Ensure Firestore is ready for new backups after data deletion
  Future<bool> ensureFirestoreReadyAfterDeletion() async {
    try {
      print(
          '🔄 [FIRESTORE_READY] Ensuring Firestore is ready for new backups...');

      // Verify user is authenticated
      final userId = _authService.getUserId();
      if (userId == null) {
        print('❌ [FIRESTORE_READY] User not authenticated');
        return false;
      }

      // Test Firestore connection
      await _getUserSettingsDocument().get();

      print('✅ [FIRESTORE_READY] Firestore is ready for new backups');
      return true;
    } catch (e) {
      print('❌ [FIRESTORE_READY] Error ensuring Firestore readiness: $e');
      return false;
    }
  }

  // Test Firestore connection
  Future<bool> testFirestoreConnection() async {
    try {
      print('🧪 [FIRESTORE_TEST] Testing Firestore connection...');

      final userId = _authService.getUserId();
      if (userId == null) {
        print('❌ [FIRESTORE_TEST] User not authenticated');
        return false;
      }

      // Test basic read operation
      await _getUserSettingsDocument().get();

      print('✅ [FIRESTORE_TEST] Firestore connection test successful');
      print(
          '✅ [FIRESTORE_TEST] User: ${_authService.getUserEmail()} ($userId)');
      return true;
    } catch (e, stackTrace) {
      print('❌ [FIRESTORE_TEST] Firestore connection test failed: $e');
      print('❌ [FIRESTORE_TEST] Stack trace: $stackTrace');
      return false;
    }
  }

  // ========== DATE-WISE EXPENSE ORGANIZATION METHODS ==========

  // Sync expense to Firestore organized by date
  // Structure: users/{userId}/expenses_by_date/{YYYY-MM-DD}/items/{expenseId}
  Future<void> syncExpenseByDate(Expense expense) async {
    try {
      final dateKey = _getDateKey(expense.date);
      final dateDoc = _getDateDocument(expense.date);
      final expenseDoc = dateDoc.collection('items').doc(expense.id);

      // Save expense data
      await expenseDoc.set(expense.toJson());

      // Update date document metadata
      await dateDoc.set({
        'date': expense.date.toIso8601String(),
        'dateKey': dateKey,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Synced expense ${expense.id} to date: $dateKey');
    } catch (e) {
      print('Error syncing expense by date to Firestore: $e');
      rethrow;
    }
  }

  // Sync all expenses organized by date
  Future<void> syncAllExpensesByDate(List<Expense> expenses) async {
    try {
      print('💾 Syncing ${expenses.length} expenses organized by date...');
      final batch = _firestore.batch();
      final Map<String, List<Expense>> expensesByDate = {};

      // Group expenses by date
      for (var expense in expenses) {
        final dateKey = _getDateKey(expense.date);
        expensesByDate.putIfAbsent(dateKey, () => []).add(expense);
      }

      // Batch write all expenses
      for (var dateKey in expensesByDate.keys) {
        final dateExpenses = expensesByDate[dateKey]!;
        final firstExpense = dateExpenses.first;
        final dateDoc = _getDateDocument(firstExpense.date);

        // Update date document metadata
        batch.set(
            dateDoc,
            {
              'date': firstExpense.date.toIso8601String(),
              'dateKey': dateKey,
              'expenseCount': dateExpenses.length,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        // Add all expenses for this date
        for (var expense in dateExpenses) {
          final expenseDoc = dateDoc.collection('items').doc(expense.id);
          batch.set(expenseDoc, expense.toJson());
        }
      }

      await batch.commit();
      print(
          '✅ Synced ${expenses.length} expenses across ${expensesByDate.length} dates');
    } catch (e) {
      print('Error syncing expenses by date to Firestore: $e');
      rethrow;
    }
  }

  // Get all expenses organized by date
  Future<List<Expense>> getAllExpensesByDate() async {
    try {
      print('📥 Fetching expenses organized by date...');
      final List<Expense> allExpenses = [];

      // Get all date documents
      final datesSnapshot = await _getExpensesByDateCollection().get();

      for (var dateDoc in datesSnapshot.docs) {
        // Get all expenses for this date
        final expensesSnapshot =
            await dateDoc.reference.collection('items').get();

        for (var expenseDoc in expensesSnapshot.docs) {
          final expense = Expense.fromJson(expenseDoc.data());
          allExpenses.add(expense);
        }
      }

      print(
          '✅ Fetched ${allExpenses.length} expenses from date-organized structure');
      return allExpenses;
    } catch (e) {
      print('Error getting expenses by date from Firestore: $e');
      return [];
    }
  }

  // Get expenses for a specific date
  Future<List<Expense>> getExpensesForSpecificDate(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      print('📥 Fetching expenses for date: $dateKey');

      final expensesSnapshot = await _getExpensesForDate(date).get();

      final expenses = expensesSnapshot.docs
          .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      print('✅ Found ${expenses.length} expenses for $dateKey');
      return expenses;
    } catch (e) {
      print('Error getting expenses for date from Firestore: $e');
      return [];
    }
  }

  // Get expenses for a date range
  Future<List<Expense>> getExpensesForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      print(
          '📥 Fetching expenses from ${_getDateKey(startDate)} to ${_getDateKey(endDate)}');
      final List<Expense> allExpenses = [];

      // Get all date documents in range
      final startKey = _getDateKey(startDate);
      final endKey = _getDateKey(endDate);

      final datesSnapshot = await _getExpensesByDateCollection()
          .where('dateKey', isGreaterThanOrEqualTo: startKey)
          .where('dateKey', isLessThanOrEqualTo: endKey)
          .get();

      for (var dateDoc in datesSnapshot.docs) {
        final expensesSnapshot =
            await dateDoc.reference.collection('items').get();

        for (var expenseDoc in expensesSnapshot.docs) {
          final expense = Expense.fromJson(expenseDoc.data());
          allExpenses.add(expense);
        }
      }

      print('✅ Fetched ${allExpenses.length} expenses for date range');
      return allExpenses;
    } catch (e) {
      print('Error getting expenses for date range from Firestore: $e');
      return [];
    }
  }

  // Delete expense from date-organized structure
  Future<void> deleteExpenseByDate(Expense expense) async {
    try {
      final dateDoc = _getDateDocument(expense.date);
      final expenseDoc = dateDoc.collection('items').doc(expense.id);

      await expenseDoc.delete();

      // Check if date document has any remaining expenses
      final remainingExpenses = await dateDoc.collection('items').get();
      if (remainingExpenses.docs.isEmpty) {
        // Delete the date document if no expenses remain
        await dateDoc.delete();
        print(
            '✅ Deleted date document ${_getDateKey(expense.date)} (no expenses remaining)');
      } else {
        // Update count
        await dateDoc.update({
          'expenseCount': remainingExpenses.docs.length,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print(
          '✅ Deleted expense ${expense.id} from date: ${_getDateKey(expense.date)}');
    } catch (e) {
      print('Error deleting expense by date from Firestore: $e');
      rethrow;
    }
  }

  // Clear all date-organized expenses
  Future<void> clearAllExpensesByDate() async {
    try {
      print('🗑️ Clearing all date-organized expenses...');

      // Get all date documents
      final datesSnapshot = await _getExpensesByDateCollection().get();
      final batch = _firestore.batch();

      for (var dateDoc in datesSnapshot.docs) {
        // Get all expenses for this date
        final expensesSnapshot =
            await dateDoc.reference.collection('items').get();

        // Delete all expense documents
        for (var expenseDoc in expensesSnapshot.docs) {
          batch.delete(expenseDoc.reference);
        }

        // Delete the date document
        batch.delete(dateDoc.reference);
      }

      await batch.commit();
      print('✅ Cleared all date-organized expenses');
    } catch (e) {
      print('Error clearing date-organized expenses from Firestore: $e');
      rethrow;
    }
  }

  // Stream of expenses for a specific date (real-time)
  Stream<List<Expense>> expensesStreamForDate(DateTime date) {
    return _getExpensesForDate(date).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get all dates that have expenses
  Future<List<DateTime>> getAllExpenseDates() async {
    try {
      final datesSnapshot = await _getExpensesByDateCollection().get();

      final dates = datesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DateTime.parse(data['date']);
      }).toList();

      dates.sort((a, b) => b.compareTo(a)); // Sort newest first

      print('✅ Found ${dates.length} dates with expenses');
      return dates;
    } catch (e) {
      print('Error getting expense dates from Firestore: $e');
      return [];
    }
  }
}
