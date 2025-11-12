import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use the singleton instance
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

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
      // Try lightweight authentication first
      GoogleSignInAccount? account =
          await _googleSignIn.attemptLightweightAuthentication();

      // If no account, try full authentication
      account ??= await _googleSignIn.authenticate(
        scopeHint: [
          'email',
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.appdata',
        ],
      );

      return account;
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
}
