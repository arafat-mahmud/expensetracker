import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deposit_model.dart';
import 'auth_service.dart';

class DepositFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get user's deposit profiles collection
  CollectionReference _getDepositProfilesCollection() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('deposit_profiles');
  }

  // Get user's deposit transactions collection
  CollectionReference _getDepositTransactionsCollection() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('deposit_transactions');
  }

  // Get user's settings document
  DocumentReference _getUserSettingsDocument() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId);
  }

  // ========== PROFILE SYNC METHODS ==========

  // Sync profile to Firestore
  Future<void> syncProfile(DepositProfile profile) async {
    try {
      await _getDepositProfilesCollection()
          .doc(profile.id)
          .set(profile.toJson());
    } catch (e) {
      print('Error syncing deposit profile to Firestore: $e');
      rethrow;
    }
  }

  // Sync all profiles to Firestore
  Future<void> syncAllProfiles(List<DepositProfile> profiles) async {
    try {
      final batch = _firestore.batch();
      final collection = _getDepositProfilesCollection();

      for (var profile in profiles) {
        batch.set(collection.doc(profile.id), profile.toJson());
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing all deposit profiles to Firestore: $e');
      rethrow;
    }
  }

  // Delete profile from Firestore
  Future<void> deleteProfile(String profileId) async {
    try {
      await _getDepositProfilesCollection().doc(profileId).delete();

      // Also delete all transactions for this profile
      final transactionsSnapshot = await _getDepositTransactionsCollection()
          .where('profileId', isEqualTo: profileId)
          .get();

      final batch = _firestore.batch();
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting deposit profile from Firestore: $e');
      rethrow;
    }
  }

  // Get all profiles from Firestore
  Future<List<DepositProfile>> getAllProfiles() async {
    try {
      final snapshot = await _getDepositProfilesCollection().get();
      return snapshot.docs
          .map((doc) =>
              DepositProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting deposit profiles from Firestore: $e');
      return [];
    }
  }

  // ========== TRANSACTION SYNC METHODS ==========

  // Sync transaction to Firestore
  Future<void> syncTransaction(DepositTransaction transaction) async {
    try {
      await _getDepositTransactionsCollection()
          .doc(transaction.id)
          .set(transaction.toJson());
    } catch (e) {
      print('Error syncing deposit transaction to Firestore: $e');
      rethrow;
    }
  }

  // Sync all transactions to Firestore
  Future<void> syncAllTransactions(
      List<DepositTransaction> transactions) async {
    try {
      final batch = _firestore.batch();
      final collection = _getDepositTransactionsCollection();

      for (var transaction in transactions) {
        batch.set(collection.doc(transaction.id), transaction.toJson());
      }

      await batch.commit();
    } catch (e) {
      print('Error syncing all deposit transactions to Firestore: $e');
      rethrow;
    }
  }

  // Delete transaction from Firestore
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _getDepositTransactionsCollection().doc(transactionId).delete();
    } catch (e) {
      print('Error deleting deposit transaction from Firestore: $e');
      rethrow;
    }
  }

  // Get all transactions from Firestore
  Future<List<DepositTransaction>> getAllTransactions() async {
    try {
      final snapshot = await _getDepositTransactionsCollection().get();
      return snapshot.docs
          .map((doc) =>
              DepositTransaction.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting deposit transactions from Firestore: $e');
      return [];
    }
  }

  // Get transactions for a profile
  Future<List<DepositTransaction>> getTransactionsForProfile(
      String profileId) async {
    try {
      final snapshot = await _getDepositTransactionsCollection()
          .where('profileId', isEqualTo: profileId)
          .get();
      return snapshot.docs
          .map((doc) =>
              DepositTransaction.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting transactions for profile from Firestore: $e');
      return [];
    }
  }

  // ========== BACKUP & RESTORE METHODS ==========

  // Backup all deposit data to Firestore
  Future<bool> backupDepositData(List<DepositProfile> profiles,
      List<DepositTransaction> transactions) async {
    try {
      print(
          '💾 [DEPOSIT_BACKUP] Starting backup: ${profiles.length} profiles, ${transactions.length} transactions...');

      // Sync all profiles
      await syncAllProfiles(profiles);
      print('✅ [DEPOSIT_BACKUP] Synced profiles');

      // Sync all transactions
      await syncAllTransactions(transactions);
      print('✅ [DEPOSIT_BACKUP] Synced transactions');

      // Update backup metadata
      await _getUserSettingsDocument().set({
        'lastDepositBackupTime': FieldValue.serverTimestamp(),
        'depositProfilesCount': profiles.length,
        'depositTransactionsCount': transactions.length,
      }, SetOptions(merge: true));

      print('✅ [DEPOSIT_BACKUP] Backup completed successfully!');
      return true;
    } catch (e, stackTrace) {
      print('❌ [DEPOSIT_BACKUP] Error backing up deposit data: $e');
      print('❌ [DEPOSIT_BACKUP] Stack trace: $stackTrace');
      return false;
    }
  }

  // Restore all deposit data from Firestore
  Future<Map<String, dynamic>?> restoreDepositData() async {
    try {
      print('📥 [DEPOSIT_RESTORE] Starting restore...');

      final profiles = await getAllProfiles();
      final transactions = await getAllTransactions();

      if (profiles.isEmpty && transactions.isEmpty) {
        print('ℹ️ [DEPOSIT_RESTORE] No backup data found');
        return null;
      }

      print(
          '✅ [DEPOSIT_RESTORE] Restored ${profiles.length} profiles, ${transactions.length} transactions');
      return {
        'profiles': profiles,
        'transactions': transactions,
      };
    } catch (e, stackTrace) {
      print('❌ [DEPOSIT_RESTORE] Error restoring deposit data: $e');
      print('❌ [DEPOSIT_RESTORE] Stack trace: $stackTrace');
      return null;
    }
  }

  // Delete all deposit backup data from Firestore
  Future<bool> deleteAllDepositBackupData() async {
    try {
      print('🗑️ [DEPOSIT_DELETE] Deleting all deposit backup data...');

      // Delete all profiles
      final profilesSnapshot = await _getDepositProfilesCollection().get();
      final profilesBatch = _firestore.batch();
      for (var doc in profilesSnapshot.docs) {
        profilesBatch.delete(doc.reference);
      }
      await profilesBatch.commit();

      // Delete all transactions
      final transactionsSnapshot =
          await _getDepositTransactionsCollection().get();
      final transactionsBatch = _firestore.batch();
      for (var doc in transactionsSnapshot.docs) {
        transactionsBatch.delete(doc.reference);
      }
      await transactionsBatch.commit();

      print('✅ [DEPOSIT_DELETE] All deposit backup data deleted');
      return true;
    } catch (e, stackTrace) {
      print('❌ [DEPOSIT_DELETE] Error deleting deposit data: $e');
      print('❌ [DEPOSIT_DELETE] Stack trace: $stackTrace');
      return false;
    }
  }

  // Get last deposit backup time
  Future<DateTime?> getLastBackupTime() async {
    try {
      final doc = await _getUserSettingsDocument().get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['lastDepositBackupTime'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      print('Error getting last deposit backup time: $e');
      return null;
    }
  }
}
