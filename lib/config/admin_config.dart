import 'package:firebase_auth/firebase_auth.dart';

/// Who may use the admin panel.
///
/// Keep this list identical to `isAdmin()` in firestore.rules. The rules are
/// what actually grant admin rights on the server; this list only decides
/// whether the app shows the admin panel.
class AdminConfig {
  static const adminEmails = {'arafat.mahmud.2001@gmail.com'};

  /// Shown to blocked users who want to get in touch
  static const supportEmail = 'arafat.mahmud.2001@gmail.com';

  static bool isAdmin(User? user) {
    final email = user?.email?.toLowerCase();
    return user != null && user.emailVerified && adminEmails.contains(email);
  }
}
