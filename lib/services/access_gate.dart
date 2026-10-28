import 'package:flutter/foundation.dart';

/// Whether this device may use the cloud right now.
///
/// Closed until the account is known to be approved, and whenever the
/// administrator blocks the user, starts maintenance or switches cloud sync
/// off. Sync code checks it, so changes wait on the device (and sync later)
/// instead of being sent and rejected by the security rules.
class AccessGate {
  static final ValueNotifier<bool> cloudAllowed = ValueNotifier(false);
}
