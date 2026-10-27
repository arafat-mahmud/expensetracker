import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check: once enforced in the Firebase console, Firestore only
/// accepts requests from the genuine app installed from Google Play (verified
/// by Play Integrity). The API key inside the APK is public by design; this is
/// what stops scripts from reusing it to read data or burn the free quota.
///
/// Debug builds use the debug provider. Its token is printed to the device
/// log; add it under App Check > Manage debug tokens to keep debug builds
/// working after enforcement.
Future<void> activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestWithDeviceCheckFallbackProvider()
          : const AppleDebugProvider(),
    );
  } catch (e) {
    print('⚠️ [APP_CHECK] Activation failed: $e');
  }
}
