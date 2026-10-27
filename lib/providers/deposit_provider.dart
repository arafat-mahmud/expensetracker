import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/deposit_model.dart';
import '../services/hive_service.dart';
import '../services/deposit_firestore_service.dart';
import '../services/auth_service.dart';
import '../services/sync_queue_service.dart';
import '../services/collection_sync.dart';

class DepositProvider with ChangeNotifier {
  List<DepositProfile> _profiles = [];
  List<DepositTransaction> _transactions = [];
  final bool _autoSync = true;
  DateTime? _lastBackupTime;
  final DepositFirestoreService _firestoreService = DepositFirestoreService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  // Keep profiles and transactions in step across the user's devices
  late final CollectionSync _profilesSync = CollectionSync(
    scope: 'deposit_profiles',
    entity: 'deposit_profile',
    collection: _firestoreService.getUserDepositProfilesCollection,
    isLocalEmpty: () => HiveService.getDepositProfilesBox().isEmpty,
    apply: (changes) => _applyRemoteChanges(
      HiveService.getDepositProfilesBox(),
      'deposit_profile',
      changes,
      DepositProfile.fromJson,
    ),
  );
  late final CollectionSync _transactionsSync = CollectionSync(
    scope: 'deposit_transactions',
    entity: 'deposit_transaction',
    collection: _firestoreService.getUserDepositTransactionsCollection,
    isLocalEmpty: () => HiveService.getDepositTransactionsBox().isEmpty,
    apply: (changes) => _applyRemoteChanges(
      HiveService.getDepositTransactionsBox(),
      'deposit_transaction',
      changes,
      DepositTransaction.fromJson,
    ),
  );

  // Callback for when a goal is completed (for showing celebration dialog)
  Function(DepositProfile)? onGoalCompleted;

  List<DepositProfile> get profiles => _profiles;
  List<DepositTransaction> get transactions => _transactions;
  DateTime? get lastBackupTime => _lastBackupTime;

  // Get active profiles (not completed)
  List<DepositProfile> get activeProfiles =>
      _profiles.where((p) => !p.isCompleted).toList();

  // Get completed profiles
  List<DepositProfile> get completedProfiles =>
      _profiles.where((p) => p.isCompleted).toList();

  DepositProvider() {
    _currentUserId = _authService.getUserId();
    loadData();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      final newUserId = user?.uid;
      if (_currentUserId != newUserId) {
        print(
            'DepositProvider: User switch detected from $_currentUserId to $newUserId');
        _currentUserId = newUserId;
        if (newUserId != null) {
          reloadForNewUser();
        } else {
          _clearDataOnSignOut();
        }
      }
    });
  }

  void _clearDataOnSignOut() {
    print('DepositProvider: Clearing data on sign out');
    _profilesSync.stop();
    _transactionsSync.stop();
    _profiles = [];
    _transactions = [];
    _lastBackupTime = null;
    notifyListeners();
  }

  Future<void> reloadForNewUser() async {
    print('🔄 DepositProvider: Reloading for new user...');
    _profiles = [];
    _transactions = [];
    _lastBackupTime = null;
    notifyListeners();

    _profilesSync.stop();
    _transactionsSync.stop();
    loadData();
    // Cloud sync starts when the savings dashboard is opened
    // (startCloudSync), so users who never use it spend no reads on it.
    // Local data needs no re-upload: every change was already queued as a
    // single-document write when it was made.
  }

  void loadData() {
    _profiles = HiveService.getAllDepositProfiles();
    _transactions = HiveService.getAllDepositTransactions();
    // Sort profiles: active first, then by deadline
    _profiles.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.deadline.compareTo(b.deadline);
    });
    // Sort transactions by date (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // ========== PROFILE CRUD (one Firestore write per changed doc) ==========

  Future<void> addProfile(DepositProfile profile) async {
    await HiveService.addDepositProfile(profile);
    loadData();

    if (_autoSync) {
      await SyncQueueService().enqueueDepositProfileUpsert(profile, isNew: true);
    }
  }

  Future<void> updateProfile(DepositProfile profile) async {
    await HiveService.updateDepositProfile(profile);
    loadData();

    if (_autoSync) {
      await SyncQueueService().enqueueDepositProfileUpsert(profile);
    }
  }

  Future<void> deleteProfile(String profileId) async {
    // The profile's transaction ids are known locally, so no Firestore query
    // (and no reads) is needed to find them
    final transactionIds = _transactions
        .where((t) => t.profileId == profileId)
        .map((t) => t.id)
        .toList();

    await HiveService.deleteDepositProfile(profileId);
    loadData();

    if (_autoSync) {
      final syncQueue = SyncQueueService();
      await syncQueue.enqueueDepositProfileDelete(profileId);
      for (final id in transactionIds) {
        await syncQueue.enqueueDepositTransactionDelete(id);
      }
    }
  }

  // ========== TRANSACTION CRUD (one Firestore write per changed doc) ==========

  Future<void> addTransaction(DepositTransaction transaction) async {
    await HiveService.addDepositTransaction(transaction);
    loadData();

    // Check if profile is now completed
    final profile = getProfileById(transaction.profileId);
    if (profile != null) {
      await checkAndUpdateCompletion(profile);
    }

    if (_autoSync) {
      await SyncQueueService()
          .enqueueDepositTransactionUpsert(transaction, isNew: true);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final transaction = _transactions.firstWhere((t) => t.id == transactionId);
    final profileId = transaction.profileId;

    await HiveService.deleteDepositTransaction(transactionId);
    loadData();

    // Check if profile completion status should change
    final profile = getProfileById(profileId);
    if (profile != null && profile.isCompleted) {
      // Re-check completion after deletion
      final balance = getProfileBalance(profileId);
      if (balance < profile.targetAmount) {
        await updateProfile(profile.copyWith(
          isCompleted: false,
          completedDate: null,
        ));
      }
    }

    if (_autoSync) {
      await SyncQueueService().enqueueDepositTransactionDelete(transactionId);
    }
  }

  // ========== CALCULATIONS ==========

  DepositProfile? getProfileById(String profileId) {
    try {
      return _profiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  double getProfileBalance(String profileId) {
    final profileTransactions =
        _transactions.where((t) => t.profileId == profileId);

    double balance = 0;
    for (var t in profileTransactions) {
      if (t.isDeposit) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  double getProfileProgress(String profileId) {
    final profile = getProfileById(profileId);
    if (profile == null || profile.targetAmount <= 0) return 0;

    final balance = getProfileBalance(profileId);
    final progress = balance / profile.targetAmount;
    return progress.clamp(0.0, 1.0);
  }

  List<DepositTransaction> getTransactionsForProfile(String profileId) {
    return _transactions.where((t) => t.profileId == profileId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getRemainingAmount(String profileId) {
    final profile = getProfileById(profileId);
    if (profile == null) return 0;
    return (profile.targetAmount - getProfileBalance(profileId))
        .clamp(0, double.infinity);
  }

  int getDaysRemaining(String profileId) {
    final profile = getProfileById(profileId);
    if (profile == null) return 0;
    return profile.deadline.difference(DateTime.now()).inDays;
  }

  bool isOnTrack(String profileId) {
    final profile = getProfileById(profileId);
    if (profile == null) return false;
    if (profile.isCompleted) return true;

    final totalDays = profile.deadline.difference(profile.createdDate).inDays;
    final daysElapsed = DateTime.now().difference(profile.createdDate).inDays;
    final expectedProgress = totalDays > 0 ? daysElapsed / totalDays : 0.0;
    final actualProgress = getProfileProgress(profileId);

    return actualProgress >= expectedProgress * 0.9; // 10% tolerance
  }

  // Auto-completion check
  Future<void> checkAndUpdateCompletion(DepositProfile profile) async {
    if (profile.isCompleted) return;

    final balance = getProfileBalance(profile.id);
    if (balance >= profile.targetAmount) {
      final completedProfile = profile.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      );

      await updateProfile(completedProfile);

      // Trigger celebration callback
      if (onGoalCompleted != null) {
        onGoalCompleted!(completedProfile);
      }
    }
  }

  // ========== BACKUP & RESTORE ==========

  // Rewrites every profile and transaction, so it is never called automatically
  Future<bool> backupToFirestore() async {
    try {
      await SyncQueueService().flushPendingOps();
      final success = await _firestoreService.backupDepositData(
        _profiles,
        _transactions,
      );
      if (success) {
        _lastBackupTime = DateTime.now();
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Failed to backup deposit data: $e');
      return false;
    }
  }

  /// Loads the user's savings data if this device needs it, then keeps
  /// listening for changes made on their other devices (see CollectionSync).
  /// Cheap to call again, e.g. from pull-to-refresh.
  /// Returns true when saved data was loaded into an empty local store.
  Future<bool> startCloudSync() async {
    final loaded =
        await Future.wait([_profilesSync.start(), _transactionsSync.start()]);
    return loaded.contains(true) && _profiles.isNotEmpty;
  }

  Future<void> _applyRemoteChanges<T>(
    Box<T> box,
    String entity,
    RemoteChanges changes,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (changes.wiped) {
      // Data was wiped on another device; keep only writes still queued here
      final pending = SyncQueueService().pendingDocIds([entity]);
      await box.deleteAll(
          box.keys.where((id) => !pending.contains(id.toString())).toList());
    }
    await HiveService.applyRemote(
      box,
      parseRemoteDocs(changes.upserts, fromJson),
      changes.deletedIds,
    );
    loadData();
  }

  Future<bool> permanentlyDeleteAllData() async {
    try {
      // Clear local data (and queued writes for docs about to be deleted)
      final syncQueue = SyncQueueService();
      await syncQueue.discardPendingOps('deposit_profile');
      await syncQueue.discardPendingOps('deposit_transaction');
      await HiveService.clearAllDepositData();
      loadData();

      // Clear cloud data
      final firestoreSuccess =
          await _firestoreService.deleteAllDepositBackupData();

      _lastBackupTime = null;
      notifyListeners();

      return firestoreSuccess;
    } catch (e) {
      print('Failed to permanently delete deposit data: $e');
      return false;
    }
  }

  // Get total deposits across all profiles
  double get totalDeposited {
    return _transactions
        .where((t) => t.isDeposit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get total withdrawn across all profiles
  double get totalWithdrawn {
    return _transactions
        .where((t) => t.isWithdraw)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get total balance across all profiles
  double get totalBalance => totalDeposited - totalWithdrawn;
}
