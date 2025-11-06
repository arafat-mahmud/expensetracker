# Google Drive Integration Checklist

## ✅ Code Implementation Status

### Backend Services
- [x] Google Drive Service implemented (`lib/services/google_drive_service.dart`)
- [x] Auth Service with Drive scopes (`lib/services/auth_service.dart`)
- [x] Auto-backup on add expense
- [x] Auto-backup on update expense
- [x] Auto-backup on delete expense
- [x] Manual backup function
- [x] Restore from backup function
- [x] Last backup timestamp tracking

### UI Integration
- [x] Settings page with backup controls
- [x] Loading indicators during backup
- [x] Success/error messages
- [x] Last backup time display
- [x] Auto-sync toggle

### Dependencies
- [x] googleapis: ^13.2.0
- [x] googleapis_auth: ^1.6.0
- [x] extension_google_sign_in_as_googleapis_auth: ^2.0.12
- [x] http: ^1.2.0
- [x] google_sign_in: ^6.2.1

## 🔧 Required Google Cloud Console Setup

### 1. Enable Required APIs
Go to: https://console.cloud.google.com/apis/library

- [ ] Enable **Google Drive API**
- [ ] Enable **Firebase Authentication API**
- [ ] Enable **Google Sign-In**

### 2. Configure OAuth Consent Screen
Go to: https://console.cloud.google.com/apis/credentials/consent

- [ ] Add app name: "Expense Tracker" (or your app name)
- [ ] Add support email
- [ ] Add authorized domains (if needed)
- [ ] Add scopes:
  - `email`
  - `https://www.googleapis.com/auth/drive.file`
  - `https://www.googleapis.com/auth/drive.appdata`

### 3. Create OAuth 2.0 Credentials

#### Android OAuth Client
Go to: https://console.cloud.google.com/apis/credentials

- [ ] Create OAuth 2.0 Client ID
- [ ] Application type: **Android**
- [ ] Package name: Get from `android/app/build.gradle.kts`
- [ ] SHA-1 certificate fingerprint:
  ```bash
  # Debug certificate (for testing)
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  
  # Release certificate (for production)
  keytool -list -v -keystore /path/to/your/release.keystore
  ```
- [ ] Copy the Client ID (needed for Firebase)

#### iOS OAuth Client (if supporting iOS)
- [ ] Create OAuth 2.0 Client ID
- [ ] Application type: **iOS**
- [ ] Bundle ID: Get from `ios/Runner.xcodeproj/project.pbxproj`
- [ ] Copy the Client ID (needed for Firebase)

### 4. Firebase Configuration
Go to: https://console.firebase.google.com/

- [ ] Select your project
- [ ] Go to Authentication > Sign-in method
- [ ] Enable **Google** sign-in provider
- [ ] Add Android OAuth Client ID (Web SDK configuration)
- [ ] Add iOS OAuth Client ID (if applicable)
- [ ] Download updated `google-services.json` (Android)
- [ ] Download updated `GoogleService-Info.plist` (iOS)

## 📱 Platform-Specific Setup

### Android
- [x] `google-services.json` in `android/app/`
- [x] Google Sign-In configuration in code
- [x] Drive scopes in AuthService
- [ ] Verify SHA-1 fingerprint in Firebase Console
- [ ] Test on real device (recommended)

### iOS
- [x] `GoogleService-Info.plist` in `ios/Runner/`
- [x] Google Sign-In configuration in code
- [ ] Update `Info.plist` with URL schemes (if needed)
- [ ] Test on real device or simulator

## 🧪 Testing Checklist

### Basic Functionality
- [ ] Sign in with Google works
- [ ] Can add an expense
- [ ] Can see "backed up to Google Drive" message
- [ ] Can view backup timestamp in Settings
- [ ] Can perform manual backup from Settings
- [ ] Can restore from backup

### Google Drive Verification
- [ ] "Expense Tracker" folder appears in Google Drive root
- [ ] `expenses_backup.json` file exists in the folder
- [ ] File updates when adding new expenses
- [ ] File updates when editing expenses
- [ ] File updates when deleting expenses

### Edge Cases
- [ ] Works without internet (local save only)
- [ ] Resumes backup when internet returns
- [ ] Handles cancelled Google Sign-In
- [ ] Shows appropriate error messages
- [ ] Handles Google Drive storage full
- [ ] Works with multiple Google accounts

## 🚨 Common Issues & Solutions

### Issue: "Sign-in failed" or "10:"
**Solution:**
- Verify SHA-1 fingerprint is added to Firebase
- Ensure `google-services.json` is up to date
- Check package name matches exactly

### Issue: "Drive API not enabled"
**Solution:**
- Enable Google Drive API in Google Cloud Console
- Wait a few minutes for changes to propagate

### Issue: "Permission denied"
**Solution:**
- Verify OAuth consent screen is configured
- Add required Drive scopes
- Sign out and sign in again

### Issue: Backup file not appearing
**Solution:**
- Check internet connection
- Verify Google Drive has storage space
- Wait a few minutes for sync
- Try manual backup

## 📋 Pre-Launch Checklist

- [ ] All APIs enabled in Google Cloud Console
- [ ] OAuth credentials configured for both Android and iOS
- [ ] Firebase Authentication configured
- [ ] SHA-1 fingerprints added to Firebase
- [ ] Tested on real Android device
- [ ] Tested on real iOS device (if applicable)
- [ ] Verified backup appears in Google Drive
- [ ] Verified restore functionality works
- [ ] Error handling works gracefully
- [ ] User feedback messages are clear
- [ ] Privacy policy mentions Google Drive usage

## 🔒 Security Notes

1. **OAuth 2.0**: App uses industry-standard OAuth 2.0
2. **Scoped Access**: Only requests necessary Drive permissions
3. **User Control**: Users can revoke access anytime
4. **Private Storage**: Data stored in user's own Drive
5. **No App Access**: App cannot access other Drive files

## 📝 Next Steps

1. Complete the Google Cloud Console setup (items marked with [ ])
2. Test the integration following the testing checklist
3. Deploy to production once all checks pass
4. Add Google Drive integration to your privacy policy
5. Consider adding backup encryption for extra security

---

**Current Status**: Code implementation complete ✅
**Remaining**: Google Cloud Console configuration and testing
