import 'package:flutter/foundation.dart';
import '../models/deposit_model.dart';
import '../services/hive_service.dart';
import '../services/deposit_firestore_service.dart';
import '../services/auth_service.dart';

class DepositProvider with ChangeNotifier {
  List<DepositProfile> _profiles = [];
  List<DepositTransaction> _transactions = [];
  final bool _autoSync = true;
  DateTime? _lastBackupTime;
  final DepositFirestoreService _firestoreService = DepositFirestoreService();
  final AuthService _authService = AuthService();
  String? _currentUserId;

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
    _loadLastBackupTime();

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

    loadData();
    await _loadLastBackupTime();

    if (_profiles.isEmpty) {
      print('No local deposit data found, attempting restore...');
      await restoreFromFirestore();
    } else {
      print('Local deposit data found, backing up...');
      await backupToFirestore();
    }
  }

  Future<void> _loadLastBackupTime() async {
    try {
      _lastBackupTime = await _firestoreService.getLastBackupTime();
      notifyListeners();
    } catch (e) {
      print('Failed to load deposit backup time: $e');
    }
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

  // ========== PROFILE CRUD ==========

  Future<void> addProfile(DepositProfile profile) async {
    await HiveService.addDepositProfile(profile);
    loadData();

    if (_autoSync) {
      try {
        await _firestoreService.syncProfile(profile);
        print('✅ Profile synced to Firestore');
      } catch (e) {
        print('❌ Failed to sync profile: $e');
      }
    }
  }

  Future<void> updateProfile(DepositProfile profile) async {
    await HiveService.updateDepositProfile(profile);
    loadData();

    if (_autoSync) {
      try {
        await _firestoreService.syncProfile(profile);
        print('✅ Profile updated in Firestore');
      } catch (e) {
        print('❌ Failed to update profile in Firestore: $e');
      }
    }
  }

  Future<void> deleteProfile(String profileId) async {
    await HiveService.deleteDepositProfile(profileId);
    loadData();

    if (_autoSync) {
      try {
        await _firestoreService.deleteProfile(profileId);
        print('✅ Profile deleted from Firestore');
      } catch (e) {
        print('❌ Failed to delete profile from Firestore: $e');
      }
    }
  }

  // ========== TRANSACTION CRUD ==========

  Future<void> addTransaction(DepositTransaction transaction) async {
    await HiveService.addDepositTransaction(transaction);
    loadData();

    // Check if profile is now completed
    final profile = getProfileById(transaction.profileId);
    if (profile != null) {
      await checkAndUpdateCompletion(profile);
    }

    if (_autoSync) {
      try {
        await _firestoreService.syncTransaction(transaction);
        print('✅ Transaction synced to Firestore');
      } catch (e) {
        print('❌ Failed to sync transaction: $e');
      }
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
      try {
        await _firestoreService.deleteTransaction(transactionId);
        print('✅ Transaction deleted from Firestore');
      } catch (e) {
        print('❌ Failed to delete transaction from Firestore: $e');
      }
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

  Future<bool> backupToFirestore() async {
    try {
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

  Future<bool> restoreFromFirestore() async {
    try {
      final restoreData = await _firestoreService.restoreDepositData();
      if (restoreData != null) {
        final profiles = restoreData['profiles'] as List<DepositProfile>? ?? [];
        final transactions =
            restoreData['transactions'] as List<DepositTransaction>? ?? [];

        // Clear existing local data first
        await HiveService.clearAllDepositData();

        // Save restored data
        for (var profile in profiles) {
          await HiveService.addDepositProfile(profile);
        }
        for (var transaction in transactions) {
          await HiveService.addDepositTransaction(transaction);
        }

        loadData();
        print(
            '✅ Deposit data restored: ${profiles.length} profiles, ${transactions.length} transactions');
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to restore deposit data: $e');
      return false;
    }
  }

  Future<bool> permanentlyDeleteAllData() async {
    try {
      // Clear local data
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
