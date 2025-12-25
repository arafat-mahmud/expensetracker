import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configure GoogleSignIn for version 6.1.6 - stable and working
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '992271188521-sgcempef6dvj7uavudrggpruohssn4am.apps.googleusercontent.com',
  );

  // Cache the Google Sign In account after successful authentication
  GoogleSignInAccount? _cachedGoogleAccount;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure clean state
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print(
            '⚠️ Sign out before sign in failed (expected if not signed in): $e');
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Check if user cancelled the sign-in
      if (googleUser == null) {
        print('User cancelled the sign-in flow');
        return null;
      }

      // Cache the Google account for later use
      _cachedGoogleAccount = googleUser;
      print('✅ Cached Google account: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      print('Google Sign In Platform Exception: $e');
      // Handle cancellation error specifically
      if (e.code == 'sign_in_canceled' ||
          e.code == 'canceled' ||
          e.message?.toLowerCase().contains('cancel') == true) {
        print('User cancelled the sign-in flow');
        return null;
      }
      rethrow;
    } catch (e) {
      print('Error signing in with Google: $e');
      // Check if it's a cancellation error in the message
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('CANCELED')) {
        print('User cancelled the sign-in flow');
        return null;
      }
      rethrow;
    }
  }

  // Get Google Sign In account for Drive API
  Future<GoogleSignInAccount?> getGoogleSignInAccount() async {
    try {
      print('🔐 [AUTH] Getting Google account for Drive API...');
      final currentFirebaseUser = _auth.currentUser;
      print('🔐 [AUTH] Current Firebase user: ${currentFirebaseUser?.email}');

      // First, check if we have a cached account from recent sign-in
      if (_cachedGoogleAccount != null) {
        print('🔐 [AUTH] Found cached account: ${_cachedGoogleAccount!.email}');
        // Validate that the cached account matches the current Firebase user
        if (currentFirebaseUser != null &&
            currentFirebaseUser.email == _cachedGoogleAccount!.email) {
          print(
              '✅ [AUTH] Using cached Google account: ${_cachedGoogleAccount!.email}');
          return _cachedGoogleAccount;
        } else {
          // Cached account doesn't match current user, clear it
          print(
              '⚠️ [AUTH] Cached account (${_cachedGoogleAccount!.email}) doesn\'t match current Firebase user (${currentFirebaseUser?.email}), clearing cache');
          _cachedGoogleAccount = null;
        }
      }

      // Skip checking current user as the API doesn't provide it directly
      print('🔐 [AUTH] Proceeding with authentication methods...');

      // Use signInSilently to get account without prompting user
      print('🔐 [AUTH] Attempting silent sign-in to get Google account...');
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      if (account != null) {
        print(
            '🔐 [AUTH] Lightweight authentication returned: ${account.email}');
        // Validate that the lightweight account matches the current Firebase user
        if (currentFirebaseUser != null &&
            currentFirebaseUser.email == account.email) {
          print(
              '✅ [AUTH] Lightweight authentication successful: ${account.email}');
          // Cache the account for future use
          _cachedGoogleAccount = account;
          return account;
        } else {
          // Account doesn't match current user, don't use it
          print(
              '⚠️ [AUTH] Lightweight account (${account.email}) doesn\'t match current Firebase user (${currentFirebaseUser?.email}), rejecting');
          return null;
        }
      }

      // If lightweight authentication fails, that's our best attempt without prompting
      print(
          '🔐 [AUTH] Lightweight authentication failed, no other silent methods available');

      // If all methods fail, user needs to sign in first
      print(
          '❌ [AUTH] All authentication methods failed - user needs to sign in first');
      return null;
    } on PlatformException catch (e) {
      print('Google Sign In Platform Exception: $e');
      // Handle cancellation error specifically
      if (e.code == 'sign_in_canceled' ||
          e.code == 'canceled' ||
          e.message?.toLowerCase().contains('cancel') == true) {
        print('User cancelled the Google Sign In');
        return null;
      }
      print('Error getting Google Sign In account: $e');
      return null;
    } catch (e) {
      print('Error getting Google Sign In account: $e');
      // Check if it's a cancellation error in the message
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('CANCELED')) {
        print('User cancelled the Google Sign In');
        return null;
      }
      return null;
    }
  }

  // Get GoogleSignIn instance (for Drive service)
  GoogleSignIn get googleSignInInstance => _googleSignIn;

  // Sign out
  Future<void> signOut() async {
    // Clear the cached Google account
    _cachedGoogleAccount = null;
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Get user display name
  String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // Get user photo URL
  String? getUserPhotoURL() {
    return _auth.currentUser?.photoURL;
  }

  // Get user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Clear cached Google account (called when different user detected)
  void clearCachedGoogleAccount() {
    if (_cachedGoogleAccount != null) {
      print(
          '🧹 Clearing cached Google account: ${_cachedGoogleAccount!.email}');
      _cachedGoogleAccount = null;
    }
  }

  // Refresh Google authentication for Drive access
  Future<bool> refreshGoogleAuthentication() async {
    try {
      print('🔄 Refreshing Google authentication...');

      // Clear cached account to force fresh authentication
      _cachedGoogleAccount = null;

      // Try to get account with fresh authentication
      final account = await getGoogleSignInAccount();
      if (account != null) {
        print(
            '✅ Google authentication refreshed successfully: ${account.email}');
        return true;
      } else {
        print('❌ Failed to refresh Google authentication');
        return false;
      }
    } catch (e) {
      print('❌ Error refreshing Google authentication: $e');
      return false;
    }
  }
}
