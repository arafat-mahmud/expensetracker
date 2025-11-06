# 🔥 Firebase & Google Drive Setup Guide

This guide will help you set up Firebase Authentication, Cloud Firestore, and Google Drive API for the SmartBudget app.

## 📋 Prerequisites

- Google Account
- Flutter project ready
- Firebase CLI installed (optional but recommended)

## 🚀 Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: **SmartBudget** (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

## 📱 Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon
2. Enter Android package name: `com.example.expensetracker` (or your package name from `android/app/build.gradle`)
3. Enter app nickname: **SmartBudget Android**
4. Leave SHA-1 empty for now (required only for release)
5. Click "Register app"
6. Download `google-services.json`
7. Place it in: `android/app/google-services.json`

### Update Android Files:

**File: `android/build.gradle`**
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**File: `android/app/build.gradle`**
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'

// Also update minSdkVersion to at least 21
android {
    defaultConfig {
        minSdkVersion 21  // Changed from flutter.minSdkVersion
    }
}
```

## 🍎 Step 3: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon
2. Enter iOS bundle ID: `com.example.expensetracker` (from `ios/Runner.xcodeproj`)
3. Enter app nickname: **SmartBudget iOS**
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Open `ios/Runner.xcworkspace` in Xcode
7. Drag `GoogleService-Info.plist` into `Runner/Runner` folder
8. Ensure "Copy items if needed" is checked
9. Click Finish

### Update iOS Files:

**File: `ios/Podfile`**
```ruby
# Uncomment this line
platform :ios, '12.0'
```

Run:
```bash
cd ios
pod install
cd ..
```

## 🔐 Step 4: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Click on "Sign-in method" tab
4. Enable **Google** sign-in:
   - Toggle the switch to enable
   - Enter project support email
   - Click "Save"

## 💾 Step 5: Enable Cloud Firestore

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (for development)
4. Choose Cloud Firestore location (select nearest to your users)
5. Click "Enable"

### Setup Firestore Security Rules:

Go to **Rules** tab and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Click "Publish"

## 📁 Step 6: Enable Google Drive API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** → **Library**
4. Search for "Google Drive API"
5. Click on it and click "Enable"

### Configure OAuth Consent Screen:

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Click "Create"
4. Fill in required fields:
   - App name: **SmartBudget**
   - User support email: your email
   - Developer contact: your email
5. Click "Save and Continue"
6. On Scopes page, click "Add or Remove Scopes"
7. Select:
   - `.../auth/drive.file`
   - `.../auth/drive.appdata`
8. Click "Update" then "Save and Continue"
9. Add test users if needed
10. Click "Save and Continue"

### Get OAuth Credentials:

1. Go to **APIs & Services** → **Credentials**
2. Click "Create Credentials" → "OAuth client ID"

#### For Android:
3. Select "Android"
4. Enter name: **SmartBudget Android**
5. Enter package name: `com.example.expensetracker`
6. Get SHA-1 certificate fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
7. Copy SHA-1 and paste it
8. Click "Create"

#### For iOS:
3. Select "iOS"
4. Enter name: **SmartBudget iOS**
5. Enter bundle ID: `com.example.expensetracker`
6. Click "Create"

#### For Web (if needed):
3. Select "Web application"
4. Enter name: **SmartBudget Web**
5. Add authorized JavaScript origins:
   - `http://localhost`
   - `http://localhost:5000`
6. Click "Create"
7. Copy the Client ID

## 🔧 Step 7: Configure Google Sign-In

### For Android:

**File: `android/app/src/main/AndroidManifest.xml`**

Add inside `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />
```

### For iOS:

**File: `ios/Runner/Info.plist`**

Add before `</dict>`:

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- TODO: Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>

<!-- Google Drive -->
<key>GIDClientID</key>
<string>YOUR-CLIENT-ID.apps.googleusercontent.com</string>
```

To find `REVERSED_CLIENT_ID`:
1. Open `GoogleService-Info.plist`
2. Find `REVERSED_CLIENT_ID` value
3. Copy and paste it in the XML above

## 🧪 Step 8: Test the Setup

Run these commands:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# For Android
flutter run -d android

# For iOS
cd ios
pod install
cd ..
flutter run -d ios
```

## ✅ Verification Checklist

- [ ] `google-services.json` in `android/app/` folder
- [ ] `GoogleService-Info.plist` in iOS Runner folder  
- [ ] Google Sign-In enabled in Firebase Console
- [ ] Cloud Firestore created and rules configured
- [ ] Google Drive API enabled
- [ ] OAuth consent screen configured
- [ ] OAuth credentials created for Android/iOS
- [ ] App runs without Firebase initialization errors

## 🐛 Common Issues & Solutions

### Issue: "FirebaseException: No Firebase App"
**Solution**: Make sure `google-services.json` and `GoogleService-Info.plist` are in correct locations and `Firebase.initializeApp()` is called in `main()`.

### Issue: "PlatformException: sign_in_failed"
**Solution**: 
- Check SHA-1 certificate is added to Firebase
- Verify package name matches in Firebase and `build.gradle`
- Re-download `google-services.json` after adding SHA-1

### Issue: "Google Drive API not enabled"
**Solution**: Go to Google Cloud Console and enable Google Drive API for your project.

### Issue: "Failed to backup to Google Drive"
**Solution**: 
- Ensure Drive API scopes are added in `auth_service.dart`
- Check OAuth consent screen includes Drive scopes
- User must grant Drive permissions during sign-in

## 📝 Important Notes

1. **Test Mode**: Firestore is in test mode. Change rules before production!
2. **SHA-1**: You need different SHA-1 for release builds
3. **Scopes**: Google Drive scopes are requested during sign-in
4. **Data Location**: Choose Firestore location carefully (can't change later)
5. **Backup**: Test backup/restore in emulator first

## 🎉 Success!

If everything is set up correctly, you should be able to:
- ✅ Sign in with Google account
- ✅ See expenses sync to Firestore automatically
- ✅ Backup data to Google Drive (in "Expense Tracker" folder)
- ✅ Restore data from Google Drive backup

## 📞 Need Help?

- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Drive API Docs](https://developers.google.com/drive/api/guides/about-sdk)
- [Flutter Fire Documentation](https://firebase.flutter.dev/)

---

**Happy Syncing! ☁️📊**
