import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _userSwitched = false; // Flag to track user switches

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get userSwitched => _userSwitched;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) async {
      await _handleUserChange(user);
    });
  }

  // Handle user authentication state changes
  Future<void> _handleUserChange(User? newUser) async {
    final previousUserId = HiveService.getCurrentUserId();
    final newUserId = newUser?.uid;

    print('🔄 User change detected:');
    print('  Previous User ID: $previousUserId');
    print('  New User ID: $newUserId');
    print('  Previous User: ${_user?.email}');
    print('  New User: ${newUser?.email}');

    // Reset user switched flag
    _userSwitched = false;

    // Check if this is a different user
    if (newUserId != null &&
        previousUserId != null &&
        newUserId != previousUserId) {
      print(
          '⚠️ Different user detected! Clearing previous user\'s local data...');

      // Set user switched flag
      _userSwitched = true;

      // Clear cached Google account from auth service
      _authService.clearCachedGoogleAccount();

      // Clear all local data from the previous user (including settings)
      await HiveService.clearAllData();
      await HiveService.clearAllSettings();
      print('✅ Previous user\'s local data and settings cleared');

      // Update the stored user ID
      await HiveService.setCurrentUserId(newUserId);
      print('✅ New user ID stored: $newUserId');
    } else if (newUserId != null && previousUserId == null) {
      // First time sign-in on this device
      print('📱 First sign-in detected, storing user ID: $newUserId');
      await HiveService.setCurrentUserId(newUserId);
    } else if (newUserId == null) {
      // User signed out
      print('👋 User signed out');

      // Clear cached Google account to prevent data leakage to next user
      _authService.clearCachedGoogleAccount();

      // Clear all local data immediately on sign out to prevent cache issues
      await HiveService.clearAllData();
      await HiveService.clearAllSettings();
      print('✅ Local data cleared on sign out');

      // Note: We don't clear the user ID here to detect user switches on next sign-in
      // The data will be cleared when a different user signs in
    }

    _user = newUser;

    // Notify listeners with additional context about user switch
    notifyListeners();

    // If user switched, notify all listeners that might need to reload data
    if (_userSwitched) {
      print('🔄 User switch completed, notifying providers to reload data...');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null) {
        _user = userCredential.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Sign in cancelled';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String? getUserEmail() {
    return _authService.getUserEmail();
  }

  String? getUserDisplayName() {
    return _authService.getUserDisplayName();
  }

  String? getUserPhotoURL() {
    return _authService.getUserPhotoURL();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Mark user switch as handled (called by other providers after they reload their data)
  void markUserSwitchHandled() {
    _userSwitched = false;
  }

  // Force clear all local data (emergency cleanup)
  Future<void> forceDataCleanup() async {
    try {
      print('🧹 AuthProvider: Force clearing all local data...');

      // Clear cached Google account
      _authService.clearCachedGoogleAccount();

      // Clear all local data
      await HiveService.clearAllData();
      await HiveService.clearAllSettings();

      print('✅ AuthProvider: Force cleanup completed');
    } catch (e) {
      print('❌ AuthProvider: Force cleanup failed: $e');
      _errorMessage = 'Failed to clear local data: $e';
      notifyListeners();
    }
  }
}
