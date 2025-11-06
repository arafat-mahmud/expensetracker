# Quick Start: Testing Google Drive Backup

## Prerequisites
✅ Code changes are complete and integrated
✅ App builds without errors
✅ You have a Google account

## Quick Test (5 minutes)

### Step 1: Enable Google Drive API (1 min)
1. Go to https://console.cloud.google.com/
2. Select your Firebase project
3. Go to "APIs & Services" > "Library"
4. Search "Google Drive API"
5. Click "Enable"

### Step 2: Configure OAuth Consent (2 min)
1. Go to "APIs & Services" > "OAuth consent screen"
2. If not already done:
   - User type: External (for testing)
   - App name: "Expense Tracker"
   - Your email as support email
   - Click "Save and Continue"
3. Add scopes:
   - Click "Add or Remove Scopes"
   - Add: `https://www.googleapis.com/auth/drive.file`
   - Click "Update" then "Save and Continue"
4. Add test users (your email)
5. Click "Save and Continue"

### Step 3: Get SHA-1 Fingerprint (1 min)
```bash
# For debug builds (testing)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

Copy the SHA1 fingerprint (format: `AA:BB:CC:...`)

### Step 4: Add SHA-1 to Firebase (1 min)
1. Go to https://console.firebase.google.com/
2. Select your project
3. Go to Project Settings (gear icon)
4. Select your Android app
5. Scroll to "SHA certificate fingerprints"
6. Click "Add fingerprint"
7. Paste the SHA-1 from Step 3
8. Download the updated `google-services.json`
9. Replace `android/app/google-services.json` with the new file

### Step 5: Run and Test
```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run on device (recommended) or emulator
flutter run
```

### Step 6: Test the Backup Flow
1. **Sign In**: Launch app → Sign in with Google
2. **Add Expense**: 
   - Tap "+" button
   - Fill: Title="Test", Amount="100", Category="Other"
   - Tap "Save"
   - ✅ Should see: "Expense added and backed up to Google Drive"

3. **Verify in Google Drive**:
   - Open Google Drive app or https://drive.google.com
   - Look for "Expense Tracker" folder
   - Open it → Should see `expenses_backup.json`
   - ✅ File should contain your test expense

4. **Test Manual Backup**:
   - Go to Settings in app
   - Tap "Backup to Google Drive"
   - ✅ Should see success message and updated timestamp

5. **Test Restore**:
   - Add another expense
   - Go to Settings
   - Tap "Restore from Google Drive"
   - Confirm
   - ✅ All expenses should be restored

## Expected Results

### ✅ Success Indicators
- ✅ Google Sign-In works without errors
- ✅ "Backed up to Google Drive" message appears after adding expense
- ✅ "Expense Tracker" folder exists in Google Drive
- ✅ JSON file contains expense data
- ✅ Manual backup updates the file
- ✅ Restore loads expenses correctly

### ❌ Common First-Time Issues

**Issue: Sign-in fails with error 10**
```
Solution: SHA-1 fingerprint not added to Firebase
→ Complete Step 3 and Step 4 above
```

**Issue: "Drive API not enabled"**
```
Solution: Google Drive API not enabled
→ Complete Step 1 above
→ Wait 1-2 minutes after enabling
```

**Issue: "Permission denied"**
```
Solution: OAuth consent not configured
→ Complete Step 2 above
→ Add your email as test user
```

**Issue: Backup silent fail (no error, no backup)**
```
Solution: Check app logs
→ Run: flutter logs | grep -i "drive\|backup"
→ Look for specific error messages
```

## Verification Script

Run this to check your setup:

```bash
# Check if google-services.json exists
ls -la android/app/google-services.json

# Check dependencies
flutter pub deps | grep -E "google_sign_in|googleapis"

# Check for compilation errors
flutter analyze

# Run with verbose logs
flutter run --verbose
```

## Need Help?

### Check Logs
```bash
# Filter for Drive-related logs
flutter logs | grep -i "drive"

# Filter for backup logs
flutter logs | grep -i "backup"

# Filter for auth logs
flutter logs | grep -i "auth\|sign"
```

### Debug Mode
The app prints detailed logs:
- ✅ "Drive API authenticated successfully"
- ✅ "Backup created successfully" or "Backup updated successfully"
- ❌ "Error backing up to Google Drive: [error]"

## Production Deployment

Once testing works:

1. **Generate Release SHA-1**:
```bash
keytool -list -v -keystore /path/to/release.keystore
```

2. **Add Release SHA-1 to Firebase**
   - Same process as Step 4, but with release fingerprint

3. **Update OAuth Consent**:
   - Change from "Testing" to "In Production"
   - Or keep in testing for gradual rollout

4. **Privacy Policy**:
   - Add Google Drive integration disclosure
   - Mention data storage in user's Drive

## Quick Troubleshooting

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| Can't sign in | SHA-1 missing | Add debug SHA-1 to Firebase |
| Sign in works, no backup | Drive API disabled | Enable in Cloud Console |
| "Permission denied" | OAuth scopes missing | Add Drive scopes in consent screen |
| File not in Drive | Wrong account | Check signed-in account |
| Backup very slow | Large data | Normal for first backup |

## Summary

✅ **What's Working**: 
- Auto-backup on add/edit/delete expense
- Manual backup and restore
- Google Drive folder organization
- User-friendly error messages

⚠️ **What You Need to Do**:
- Enable Google Drive API (Step 1)
- Configure OAuth consent (Step 2)  
- Add SHA-1 to Firebase (Steps 3-4)
- Test on real device (Step 5-6)

**Estimated Setup Time**: 5-10 minutes

---

Once you complete these steps, your expense tracker will automatically backup every expense to Google Drive! 🎉
