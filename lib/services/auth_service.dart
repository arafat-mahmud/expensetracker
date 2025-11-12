import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use the singleton instance
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  // Cache the Google Sign In account after successful authentication
  GoogleSignInAccount? _cachedGoogleAccount;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize with scopes
      await _googleSignIn.initialize();

      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: [
          'email',
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.appdata',
        ],
      );

      // Cache the Google account for later Drive API use
      _cachedGoogleAccount = googleUser;
      print('✅ Cached Google account: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

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
      // First, check if we have a cached account from recent sign-in
      if (_cachedGoogleAccount != null) {
        // Validate that the cached account matches the current Firebase user
        final currentFirebaseUser = _auth.currentUser;
        if (currentFirebaseUser != null &&
            currentFirebaseUser.email == _cachedGoogleAccount!.email) {
          print(
              '✅ Using cached Google account: ${_cachedGoogleAccount!.email}');
          return _cachedGoogleAccount;
        } else {
          // Cached account doesn't match current user, clear it
          print(
              '⚠️ Cached account (${_cachedGoogleAccount!.email}) doesn\'t match current Firebase user (${currentFirebaseUser?.email}), clearing cache');
          _cachedGoogleAccount = null;
        }
      }

      // Use lightweight authentication (uses already signed-in account without prompting)
      print('Attempting lightweight authentication to get Google account...');
      final GoogleSignInAccount? account =
          await _googleSignIn.attemptLightweightAuthentication();

      if (account != null) {
        // Validate that the lightweight account matches the current Firebase user
        final currentFirebaseUser = _auth.currentUser;
        if (currentFirebaseUser != null &&
            currentFirebaseUser.email == account.email) {
          print('✅ Lightweight authentication successful: ${account.email}');
          // Cache the account for future use
          _cachedGoogleAccount = account;
          return account;
        } else {
          // Account doesn't match current user, don't use it
          print(
              '⚠️ Lightweight account (${account.email}) doesn\'t match current Firebase user (${currentFirebaseUser?.email}), rejecting');
          return null;
        }
      }

      // If lightweight authentication fails, it means user needs to sign in first
      // DO NOT call authenticate() here as it will show the account picker again
      // The user should use the "Sign in with Google" button instead
      print(
          '⚠️ Lightweight authentication failed - user needs to sign in first');
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
}
