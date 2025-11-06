# Google Drive Integration Setup Guide

## Overview
Your Expense Tracker app now automatically backs up all expenses to Google Drive in a folder named "Expense Tracker" whenever you add, update, or delete an expense.

## Features
✅ **Auto-backup**: Expenses are automatically saved to Google Drive when auto-sync is enabled
✅ **Folder Organization**: All backups are stored in a dedicated "Expense Tracker" folder
✅ **Manual Backup**: You can manually trigger a backup from Settings
✅ **Restore**: Restore all expenses from your Google Drive backup
✅ **Last Backup Time**: View when your last backup was created

## How It Works

### 1. **Automatic Backup**
When you add, update, or delete an expense:
- The expense is saved locally in Hive database
- If auto-sync is enabled, it syncs to Firestore
- It automatically backs up ALL expenses to Google Drive in the "Expense Tracker" folder
- A JSON file named `expenses_backup.json` is created/updated

### 2. **Google Drive Folder Structure**
```
Google Drive (Root)
└── Expense Tracker/
    └── expenses_backup.json
```

### 3. **Backup Data Format**
The backup file contains:
- Backup timestamp
- User ID and email
- Total number of expenses
- All expense details (title, category, amount, date, notes)

## Testing the Integration

### Step 1: Sign In with Google
1. Open the app
2. Sign in with your Google account
3. Grant permissions for Google Drive access

### Step 2: Verify Auto-Sync is Enabled
1. Go to **Settings** page
2. Check that **Auto Sync** toggle is ON (it's enabled by default)

### Step 3: Add an Expense
1. Tap the **"+ Add Expense"** button
2. Fill in the expense details:
   - Title (e.g., "Electricity Bill")
   - Category (e.g., "Electricity")
   - Amount (e.g., "1500")
   - Date
   - Note (optional)
3. Tap **"Save Expense"**
4. You should see: "Expense added and backed up to Google Drive"

### Step 4: Verify Backup in Google Drive
1. Open Google Drive on web or mobile app
2. Look for a folder named **"Expense Tracker"**
3. Inside, you'll find **expenses_backup.json**
4. The file will be updated every time you add/edit/delete an expense

### Step 5: Test Manual Backup (Optional)
1. Go to **Settings** page
2. Tap on **"Backup to Google Drive"**
3. Wait for the backup to complete
4. You'll see the last backup timestamp updated

### Step 6: Test Restore (Optional)
1. Go to **Settings** page
2. Tap on **"Restore from Google Drive"**
3. Confirm the restore action
4. All expenses from the backup will be restored

## Troubleshooting

### Issue: "Failed to backup to Google Drive"
**Solutions:**
1. Check your internet connection
2. Verify you're signed in with Google
3. Try signing out and signing in again
4. Check Google Drive storage space
5. Revoke and re-grant permissions:
   - Go to [Google Account Security](https://myaccount.google.com/permissions)
   - Find your app and remove access
   - Sign in again to grant fresh permissions

### Issue: Backup folder not appearing in Google Drive
**Solutions:**
1. Wait a few minutes (Google Drive sync may be delayed)
2. Refresh Google Drive
3. Check if you're looking at the correct Google account
4. Try a manual backup from Settings

### Issue: Permission denied errors
**Solutions:**
1. Make sure Google Sign-In includes Drive scopes (already configured)
2. Sign out and sign in again
3. Check that both OAuth credentials are configured:
   - Android OAuth client in Google Cloud Console
   - iOS OAuth client in Google Cloud Console

## Configuration Files

### Android Configuration
- File: `android/app/google-services.json`
- Make sure your Firebase project has Google Sign-In enabled

### iOS Configuration
- File: `ios/Runner/GoogleService-Info.plist`
- Make sure your Firebase project has Google Sign-In enabled

### Required Scopes
The app requests these Google API scopes:
```dart
[
  'email',
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/drive.appdata',
]
```

## Manual Testing Commands

Run the app:
```bash
flutter run
```

Check logs for Drive operations:
```bash
flutter logs | grep -i "drive\|backup"
```

## API Permissions in Google Cloud Console

Make sure these APIs are enabled in your Google Cloud Console:
1. **Google Drive API**
2. **Firebase Authentication**

To enable:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "APIs & Services" > "Library"
4. Search for "Google Drive API"
5. Click "Enable"

## Privacy & Security

- All backups are stored in YOUR Google Drive
- Only you have access to the "Expense Tracker" folder
- The app uses OAuth 2.0 for secure authentication
- You can revoke access anytime from Google Account settings

## Support

If you encounter any issues:
1. Check the app logs for error messages
2. Verify your Google Cloud Console configuration
3. Ensure all required permissions are granted
4. Try the manual backup/restore options in Settings

---

**Note**: The first backup may take a few seconds as it creates the folder structure. Subsequent backups are faster as they just update the existing file.
