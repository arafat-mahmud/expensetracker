# Google Drive Backup Testing Guide

## Current Issue Diagnosis

The Google Drive backup might not be working due to one of these reasons:

### Common Issues:
1. **Google Drive API not enabled** in Google Cloud Console
2. **OAuth scopes not approved** by user during sign-in
3. **SHA-1 fingerprint missing** in Firebase Console
4. **Network/connectivity issues**
5. **Google account doesn't have Drive permissions**

## Step-by-Step Testing

### Step 1: Check Console Logs

Run the app with detailed logging:

```bash
cd /Users/sanon/expensetracker
flutter run --verbose | grep -i "drive\|backup\|google"
```

### Step 2: Look for These Log Messages

When you add an expense, you should see:

**✅ Success Flow:**
```
Attempting Google Drive backup...
Using existing Google account: your@email.com
Drive API authenticated successfully for: your@email.com
Starting Google Drive backup for X expenses...
Getting or creating app folder...
Folder ID: xxxxxxxxxxxxx
Backup data size: XXXX bytes
Checking for existing backup file...
Creating new backup file... (or Updating existing backup file...)
✅ Backup created successfully!
✅ Auto-backup to Google Drive successful
```

**❌ Failure Indicators:**
```
No authenticated Google account found. Please sign in first.
Failed to get Drive API - user might not be signed in
Error getting Drive API: [error details]
❌ Error backing up to Google Drive: [error details]
```

### Step 3: Test Sign-In First

Before testing backup:

1. Open the app
2. Sign in with Google
3. Check console for:
   ```
   Using existing Google account: your@email.com
   ```

### Step 4: Enable Google Drive API

**CRITICAL**: You MUST enable the Google Drive API:

1. Go to: https://console.cloud.google.com/
2. Select your Firebase project
3. Go to "APIs & Services" > "Library"
4. Search: "Google Drive API"
5. Click "ENABLE"
6. Wait 1-2 minutes

### Step 5: Verify OAuth Scopes

Check that Drive scopes are requested:

1. Sign out from the app
2. Sign in again
3. You should see permission request for:
   - View and manage files created by this app
   - See, edit, create, and delete files in your Google Drive

If you don't see this, the scopes might not be configured.

### Step 6: Add Test Expense

1. Add an expense: "Test Expense", Amount: 100
2. Watch the console logs
3. Look for the success messages above

### Step 7: Verify in Google Drive

1. Open https://drive.google.com
2. Look for "Expense Tracker" folder in the root
3. Open it
4. You should see: `expenses_backup.json`
5. Download and open it - should contain your test expense

## Quick Diagnostic Commands

### Check if app is running:
```bash
flutter devices
```

### View live logs:
```bash
flutter logs
```

### Filter for Drive-related logs only:
```bash
flutter logs | grep -E "drive|backup|Drive|Backup|DRIVE|BACKUP" --color
```

### Filter for errors only:
```bash
flutter logs | grep -i error --color
```

## Manual Test in Settings

If automatic backup isn't working:

1. Open app → Go to Settings
2. Tap "Backup to Google Drive"
3. Watch console logs
4. Check if folder appears in Google Drive

## Common Error Messages & Solutions

### Error: "No authenticated Google account found"
**Solution:**
- Sign out and sign in again
- Make sure Google Sign-In completed successfully

### Error: "API not enabled"
**Solution:**
- Enable Google Drive API in Cloud Console (Step 4 above)
- Wait 1-2 minutes after enabling

### Error: "Permission denied" or "403"
**Solution:**
- OAuth consent screen not configured
- Go to Cloud Console > APIs & Services > OAuth consent screen
- Add Drive scopes: `https://www.googleapis.com/auth/drive.file`

### Error: "401 Unauthorized"
**Solution:**
- OAuth credentials issue
- Verify SHA-1 fingerprint is in Firebase Console
- Re-download google-services.json

### Error: "Network error" or timeout
**Solution:**
- Check internet connection
- Try again after a few seconds
- Check if Google services are accessible

## Debug Mode Test Script

Run this to get maximum debug info:

```bash
# Terminal 1: Run app
cd /Users/sanon/expensetracker
flutter run --verbose

# Terminal 2: Watch logs
flutter logs | grep -i "drive\|backup\|auth\|google"
```

## What to Share if Still Not Working

If it's still not working, share these details:

1. **Console logs** when adding an expense (copy from terminal)
2. **Error messages** (the exact text)
3. **Google Cloud Console status**:
   - Is Google Drive API enabled? (Yes/No)
   - Is OAuth consent configured? (Yes/No)
4. **Firebase Console status**:
   - Is SHA-1 fingerprint added? (Yes/No)
5. **App behavior**:
   - Does sign-in work? (Yes/No)
   - Does expense save locally? (Yes/No)
   - Do you see "backed up" message? (Yes/No)

## Expected Timeline

After enabling Google Drive API:
- Wait time: 1-2 minutes
- Then test: Add an expense
- Check Drive: Should see folder within 10 seconds

## Success Checklist

- [ ] Google Drive API enabled in Cloud Console
- [ ] SHA-1 fingerprint added to Firebase
- [ ] Can sign in with Google successfully
- [ ] Console shows "Drive API authenticated successfully"
- [ ] Console shows "✅ Backup created successfully"
- [ ] "Expense Tracker" folder appears in Google Drive
- [ ] `expenses_backup.json` file contains data

## Still Having Issues?

1. Try the manual backup from Settings first
2. Check if you can see detailed error messages
3. Verify your Google account has Drive access
4. Try on a different device/emulator
5. Check if Firebase project is properly configured

---

**Most Common Fix**: Enable Google Drive API in Cloud Console and wait 2 minutes!
