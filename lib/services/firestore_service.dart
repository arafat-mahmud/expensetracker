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

  // Get user's settings document
  DocumentReference _getUserSettingsDocument() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId);
  }

  // Sync expense to Firestore
  Future<void> syncExpense(Expense expense) async {
    try {
      await _getUserExpensesCollection().doc(expense.id).set(expense.toJson());
    } catch (e) {
      print('Error syncing expense to Firestore: $e');
      rethrow;
    }
  }

  // Sync all expenses to Firestore
  Future<void> syncAllExpenses(List<Expense> expenses) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserExpensesCollection();

      for (var expense in expenses) {
        batch.set(collection.doc(expense.id), expense.toJson());
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing all expenses to Firestore: $e');
      rethrow;
    }
  }

  // Delete expense from Firestore
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _getUserExpensesCollection().doc(expenseId).delete();
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
  Future<bool> backupExpenses(List<Expense> expenses,
      {double? monthlyBudget}) async {
    try {
      print(
          '💾 [FIRESTORE_BACKUP] Starting Firestore backup for ${expenses.length} expenses...');
      print('💾 [FIRESTORE_BACKUP] User ID: ${_authService.getUserId()}');
      print('💾 [FIRESTORE_BACKUP] User email: ${_authService.getUserEmail()}');
      print('💾 [FIRESTORE_BACKUP] Monthly budget: $monthlyBudget');

      // Sync all expenses to Firestore
      await syncAllExpenses(expenses);

      // Save backup metadata and settings
      await _getUserSettingsDocument().set({
        'monthlyBudget': monthlyBudget,
        'lastBackupTime': FieldValue.serverTimestamp(),
        'backupDate': DateTime.now().toIso8601String(),
        'userId': _authService.getUserId(),
        'userEmail': _authService.getUserEmail(),
        'expensesCount': expenses.length,
      }, SetOptions(merge: true));

      print(
          '✅ [FIRESTORE_BACKUP] Backup completed successfully! ${expenses.length} expenses backed up');
      return true;
    } catch (e, stackTrace) {
      print('❌ [FIRESTORE_BACKUP] Error backing up to Firestore: $e');
      print('❌ [FIRESTORE_BACKUP] Stack trace: $stackTrace');
      return false;
    }
  }

  // Restore expenses from Firestore (replacement for Google Drive restore)
  Future<Map<String, dynamic>?> restoreExpenses() async {
    try {
      print('📥 [FIRESTORE_RESTORE] Starting Firestore restore...');

      // Get all expenses from Firestore
      final expenses = await getAllExpenses();

      // Get settings (including monthly budget)
      final settings = await getSettings();
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
  Future<bool> deleteAllBackupFiles() async {
    try {
      print(
          '🗑️ [FIRESTORE_DELETE] Starting deletion of all backup data from Firestore...');
      final stopwatch = Stopwatch()..start();

      // Clear all expenses
      await clearAllData();

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
}
