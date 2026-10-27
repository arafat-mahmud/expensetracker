import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deposit_model.dart';
import 'auth_service.dart';

class DepositFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Track last sync time to avoid redundant syncs
  DateTime? _lastSyncTime;
  static const Duration _minSyncInterval = Duration(seconds: 10);

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

  // Public getters for collections (used by sync queue)
  CollectionReference getUserDepositProfilesCollection() {
    return _getDepositProfilesCollection();
  }

  CollectionReference getUserDepositTransactionsCollection() {
    return _getDepositTransactionsCollection();
  }

  // Get user's settings document
  DocumentReference _getUserSettingsDocument() {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId);
  }

  // Check if sync is needed based on time interval
  bool _shouldSync() {
    if (_lastSyncTime == null) return true;
    return DateTime.now().difference(_lastSyncTime!) > _minSyncInterval;
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

  // Sync all profiles to Firestore (with batch optimization)
  Future<void> syncAllProfiles(List<DepositProfile> profiles) async {
    try {
      const batchSize = 450;

      for (var i = 0; i < profiles.length; i += batchSize) {
        final batch = _firestore.batch();
        final collection = _getDepositProfilesCollection();
        final end =
            (i + batchSize < profiles.length) ? i + batchSize : profiles.length;

        for (var j = i; j < end; j++) {
          batch.set(collection.doc(profiles[j].id), profiles[j].toJson());
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error syncing all deposit profiles to Firestore: $e');
      rethrow;
    }
  }

  // Delete profile from Firestore
  Future<void> deleteProfile(String profileId) async {
    try {
      await _getDepositProfilesCollection().doc(profileId).delete();

      // Also delete all transactions for this profile using batch
      final transactionsSnapshot = await _getDepositTransactionsCollection()
          .where('profileId', isEqualTo: profileId)
          .get();

      if (transactionsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in transactionsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error deleting deposit profile from Firestore: $e');
      rethrow;
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

  // Sync all transactions to Firestore (with batch optimization)
  Future<void> syncAllTransactions(
      List<DepositTransaction> transactions) async {
    try {
      const batchSize = 450;

      for (var i = 0; i < transactions.length; i += batchSize) {
        final batch = _firestore.batch();
        final collection = _getDepositTransactionsCollection();
        final end = (i + batchSize < transactions.length)
            ? i + batchSize
            : transactions.length;

        for (var j = i; j < end; j++) {
          batch.set(
              collection.doc(transactions[j].id), transactions[j].toJson());
        }

        await batch.commit();
      }
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

  // ========== BACKUP & RESTORE METHODS (optimized) ==========

  // Backup all deposit data to Firestore
  Future<bool> backupDepositData(
      List<DepositProfile> profiles, List<DepositTransaction> transactions,
      {bool force = false}) async {
    try {
      // Skip backup if recently synced and not forced
      if (!force && !_shouldSync()) {
        print('⏭️ [DEPOSIT_BACKUP] Skipping backup - recently synced');
        return true;
      }

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

      _lastSyncTime = DateTime.now();
      print('✅ [DEPOSIT_BACKUP] Backup completed successfully!');
      return true;
    } catch (e, stackTrace) {
      print('❌ [DEPOSIT_BACKUP] Error backing up deposit data: $e');
      print('❌ [DEPOSIT_BACKUP] Stack trace: $stackTrace');
      return false;
    }
  }

  // Delete all deposit backup data from Firestore (with batch optimization)
  Future<bool> deleteAllDepositBackupData() async {
    try {
      print('🗑️ [DEPOSIT_DELETE] Deleting all deposit backup data...');

      // Delete all profiles using batches
      final profilesSnapshot = await _getDepositProfilesCollection().get();
      if (profilesSnapshot.docs.isNotEmpty) {
        const batchSize = 450;
        for (var i = 0; i < profilesSnapshot.docs.length; i += batchSize) {
          final batch = _firestore.batch();
          final end = (i + batchSize < profilesSnapshot.docs.length)
              ? i + batchSize
              : profilesSnapshot.docs.length;

          for (var j = i; j < end; j++) {
            batch.delete(profilesSnapshot.docs[j].reference);
          }
          await batch.commit();
        }
      }

      // Delete all transactions using batches
      final transactionsSnapshot =
          await _getDepositTransactionsCollection().get();
      if (transactionsSnapshot.docs.isNotEmpty) {
        const batchSize = 450;
        for (var i = 0; i < transactionsSnapshot.docs.length; i += batchSize) {
          final batch = _firestore.batch();
          final end = (i + batchSize < transactionsSnapshot.docs.length)
              ? i + batchSize
              : transactionsSnapshot.docs.length;

          for (var j = i; j < end; j++) {
            batch.delete(transactionsSnapshot.docs[j].reference);
          }
          await batch.commit();
        }
      }

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
