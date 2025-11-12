import 'hive_service.dart';
import 'auth_service.dart';

/// Service to manage user data isolation and prevent data leakage between different user accounts
class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  final AuthService _authService = AuthService();
  String? _lastKnownUserId;

  /// Initialize the user data manager
  void initialize() {
    _lastKnownUserId = _authService.getUserId();
    print('UserDataManager initialized with user: $_lastKnownUserId');
  }

  /// Check if user has switched and handle data isolation
  Future<bool> checkAndHandleUserSwitch() async {
    final currentUserId = _authService.getUserId();

    if (_lastKnownUserId != currentUserId) {
      print('UserDataManager: User switch detected');
      print('  Previous: $_lastKnownUserId');
      print('  Current: $currentUserId');

      if (currentUserId != null && _lastKnownUserId != null) {
        // Different user signed in - clear all previous user's data
        await _clearPreviousUserData();
        print('✅ Previous user data cleared');
      } else if (currentUserId == null) {
        // User signed out - clear all data
        await _clearAllLocalData();
        print('✅ All local data cleared on sign out');
      }

      _lastKnownUserId = currentUserId;
      return true; // User switched
    }

    return false; // No user switch
  }

  /// Clear all data from previous user to prevent data leakage
  Future<void> _clearPreviousUserData() async {
    try {
      // Clear all local data
      await HiveService.clearAllData();
      await HiveService.clearAllSettings();

      // Clear cached Google account
      _authService.clearCachedGoogleAccount();

      // Update stored user ID
      final newUserId = _authService.getUserId();
      if (newUserId != null) {
        await HiveService.setCurrentUserId(newUserId);
      }

      print('UserDataManager: Previous user data completely cleared');
    } catch (e) {
      print('UserDataManager: Error clearing previous user data: $e');
      rethrow;
    }
  }

  /// Clear all local data (called on sign out)
  Future<void> _clearAllLocalData() async {
    try {
      await HiveService.clearAllData();
      await HiveService.clearAllSettings();
      _authService.clearCachedGoogleAccount();

      print('UserDataManager: All local data cleared');
    } catch (e) {
      print('UserDataManager: Error clearing all local data: $e');
    }
  }

  /// Force clear all data (for debugging or manual cleanup)
  Future<void> forceCleanup() async {
    await _clearAllLocalData();
    _lastKnownUserId = null;
    print('UserDataManager: Force cleanup completed');
  }

  /// Get current user info for debugging
  Map<String, dynamic> getUserInfo() {
    return {
      'lastKnownUserId': _lastKnownUserId,
      'currentUserId': _authService.getUserId(),
      'currentUserEmail': _authService.getUserEmail(),
      'storedUserId': HiveService.getCurrentUserId(),
    };
  }
}
