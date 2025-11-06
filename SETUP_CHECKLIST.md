# ✅ Quick Setup Checklist

Before running the app with Firebase features, complete these steps:

## 📋 Pre-Requirements
- [ ] Google Account created
- [ ] Flutter installed and configured
- [ ] Android Studio / Xcode installed (for respective platforms)

## 🔥 Firebase Setup (Required)
- [ ] Firebase project created at console.firebase.google.com
- [ ] Android app added to Firebase project
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] iOS app added to Firebase project (for iOS)
- [ ] `GoogleService-Info.plist` downloaded and added to iOS Runner
- [ ] Google Authentication enabled in Firebase Console
- [ ] Cloud Firestore database created
- [ ] Firestore security rules configured

## 🔧 Android Configuration
- [ ] Updated `android/build.gradle` with google-services plugin
- [ ] Updated `android/app/build.gradle` with plugin and minSdkVersion 21
- [ ] SHA-1 certificate fingerprint added to Firebase (for release)

## 🍎 iOS Configuration
- [ ] iOS platform version set to 12.0 in Podfile
- [ ] `pod install` run in ios folder
- [ ] `REVERSED_CLIENT_ID` added to Info.plist
- [ ] GIDClientID added to Info.plist

## 📁 Google Drive API Setup
- [ ] Google Drive API enabled in Google Cloud Console
- [ ] OAuth consent screen configured
- [ ] OAuth credentials created for Android
- [ ] OAuth credentials created for iOS
- [ ] Drive scopes added (drive.file, drive.appdata)
- [ ] Test users added (if using external user type)

## 🧪 Testing
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Build successful for Android
- [ ] Build successful for iOS (if applicable)
- [ ] Google Sign-In works
- [ ] Firestore sync works
- [ ] Google Drive backup works
- [ ] Google Drive restore works

## 🚀 Quick Commands

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Generate Hive adapters (if needed)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run -d android

# Run on iOS
cd ios && pod install && cd ..
flutter run -d ios

# Check for errors
flutter analyze
```

## 📝 Common First-Time Issues

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution**: Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location

### Issue: "PlatformException: sign_in_failed"
**Solution**: 
1. Add SHA-1 to Firebase Console
2. Re-download `google-services.json`
3. Rebuild the app

### Issue: "minSdkVersion error"
**Solution**: Set `minSdkVersion 21` in `android/app/build.gradle`

### Issue: "Pod install fails"
**Solution**: 
```bash
cd ios
pod repo update
pod install --repo-update
cd ..
```

### Issue: "Drive API not available"
**Solution**: Enable Google Drive API in Google Cloud Console for your Firebase project

## 🎯 What Happens Without Firebase Setup?

If you run the app without completing Firebase setup:
- ❌ Login page will show errors
- ❌ Google Sign-In will fail
- ❌ Cloud sync won't work
- ❌ Drive backup won't work
- ✅ App will crash on startup due to Firebase initialization

**You MUST complete Firebase setup before running the app!**

## 🔄 Alternative: Run Without Firebase (Not Recommended)

If you want to run without Firebase temporarily:

1. Remove Firebase initialization from `main.dart`:
```dart
// Comment out this line:
// await Firebase.initializeApp();
```

2. Remove auth check from MaterialApp:
```dart
// Change from:
home: authProvider.isAuthenticated ? const DashboardPage() : const LoginPage(),
// To:
home: const DashboardPage(),
```

**Note**: This will break cloud features completely. Only use for testing local features.

## ✅ Verification

After setup, you should:
1. See Login page when app starts
2. Be able to sign in with Google
3. See user profile in Settings
4. See "Auto Sync" toggle in Settings
5. Be able to backup to Google Drive
6. See "Expense Tracker" folder in your Google Drive

## 🎉 All Set!

Once all items are checked, you're ready to use SmartBudget with full cloud capabilities!

For detailed instructions, see: **`FIREBASE_SETUP.md`**

---

**Happy Tracking! 💰☁️**
