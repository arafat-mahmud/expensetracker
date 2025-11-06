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
}
