import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/expense_model.dart';
import 'auth_service.dart';

class GoogleDriveService {
  final AuthService _authService = AuthService();
  static const String appFolderName = 'Expense Tracker';
  static const String backupFileName = 'expenses_backup.json';

  // Get authenticated Drive API client
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      // Get existing account using lightweight authentication (no prompts)
      print('🔐 [DEBUG] Getting Google account for Drive API...');
      print('🔐 [DEBUG] Current user ID: ${_authService.getUserId()}');
      print('🔐 [DEBUG] Current user email: ${_authService.getUserEmail()}');

      GoogleSignInAccount? account =
          await _authService.getGoogleSignInAccount();

      // If no account, user needs to sign in first
      if (account == null) {
        print(
            '❌ [DEBUG] No Google account available - user needs to sign in first');
        print(
            '❌ [DEBUG] Firebase user exists: ${_authService.currentUser != null}');
        return null;
      }

      print('✅ [DEBUG] Using Google account: ${account.email}');
      print('✅ [DEBUG] Account display name: ${account.displayName}');
      print('✅ [DEBUG] Account ID: ${account.id}');

      // Get authorization for Drive API scopes silently (no user prompts)
      print('🔐 [DEBUG] Requesting authorization silently (no account picker)...');
      final authorization = await account.authorizationClient.authorizationForScopes([
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive.appdata',
      ]);

      if (authorization == null) {
        print(
            '❌ [DEBUG] Failed to get authorization silently - user may need to re-authenticate');
        return null;
      }

      print('✅ [DEBUG] Got authorization silently');
      print('✅ [DEBUG] Creating Drive API client using authorized client...');
      
      // Use the extension method to create an authenticated HTTP client
      final authenticatedClient = authorization.authClient(
        scopes: [
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.appdata',
        ],
      );
      
      final driveApi = drive.DriveApi(authenticatedClient);

      // Test the API connection
      print('🧪 [DEBUG] Testing Drive API connection...');
      try {
        await driveApi.about.get($fields: 'user');
        print('✅ [DEBUG] Drive API connection test successful');
      } catch (testError) {
        print('❌ [DEBUG] Drive API connection test failed: $testError');
        return null;
      }

      print(
          '✅ [DEBUG] Drive API authenticated successfully for: ${account.email}');
      return driveApi;
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Error getting Drive API: $e');
      print('❌ [DEBUG] Stack trace: $stackTrace');
      return null;
    }
  }

  // Find or create app folder
  Future<String?> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    try {
      print('📁 [FOLDER] Searching for existing app folder: "$appFolderName"');

      // Search for existing folder
      final fileList = await driveApi.files.list(
        q: "name='$appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, parents)',
      );

      print(
          '📁 [FOLDER] Search result: ${fileList.files?.length ?? 0} folders found');

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFolder = fileList.files!.first;
        print(
            '📁 [FOLDER] Using existing folder: ID=${existingFolder.id}, Name=${existingFolder.name}');
        print('📁 [FOLDER] Folder parents: ${existingFolder.parents}');
        return existingFolder.id;
      }

      // Create new folder
      print('📁 [FOLDER] Creating new app folder: "$appFolderName"');
      final folder = drive.File();
      folder.name = appFolderName;
      folder.mimeType = 'application/vnd.google-apps.folder';
      // Don't set parents - let it be created in root

      final createdFolder = await driveApi.files.create(folder);
      print(
          '📁 [FOLDER] Created new folder: ID=${createdFolder.id}, Name=${createdFolder.name}');

      // Verify the folder was created
      final verifyList = await driveApi.files.list(
        q: "id='${createdFolder.id}'",
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, parents)',
      );

      if (verifyList.files != null && verifyList.files!.isNotEmpty) {
        final verifiedFolder = verifyList.files!.first;
        print(
            '📁 [FOLDER] Verification successful: ${verifiedFolder.name} (${verifiedFolder.mimeType})');
      } else {
        print(
            '❌ [FOLDER] Verification failed - folder not found after creation!');
      }

      return createdFolder.id;
    } catch (e, stackTrace) {
      print('❌ [FOLDER] Error creating/finding app folder: $e');
      print('❌ [FOLDER] Stack trace: $stackTrace');
      return null;
    }
  }

  // Backup expenses to Google Drive
  Future<bool> backupExpenses(List<Expense> expenses,
      {double? monthlyBudget}) async {
    try {
      print(
          '💾 [BACKUP] Starting Google Drive backup for ${expenses.length} expenses...');
      print('💾 [BACKUP] User ID: ${_authService.getUserId()}');
      print('💾 [BACKUP] User email: ${_authService.getUserEmail()}');
      print('💾 [BACKUP] Monthly budget: $monthlyBudget');

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print(
            '❌ [BACKUP] Failed to get Drive API - user might not be signed in');
        return false;
      }

      print('📁 [BACKUP] Getting or creating app folder...');
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        print('❌ [BACKUP] Failed to get/create folder');
        return false;
      }
      print('📁 [BACKUP] Folder ID: $folderId');

      // Prepare backup data
      final backupData = {
        'backupDate': DateTime.now().toIso8601String(),
        'userId': _authService.getUserId(),
        'userEmail': _authService.getUserEmail(),
        'expensesCount': expenses.length,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'monthlyBudget': monthlyBudget,
      };

      final jsonData = jsonEncode(backupData);
      print('📄 [BACKUP] Backup data size: ${jsonData.length} bytes');
      print(
          '📄 [BACKUP] First 100 chars of JSON: ${jsonData.length > 100 ? jsonData.substring(0, 100) + "..." : jsonData}');

      final media = drive.Media(
        Stream.value(utf8.encode(jsonData)),
        jsonData.length,
      );

      print('🔍 [BACKUP] Checking for existing backup file...');
      // Check if backup file exists
      final existingFiles = await driveApi.files.list(
        q: "name='$backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      print(
          '🔍 [BACKUP] Found ${existingFiles.files?.length ?? 0} existing files');

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file
        print('📝 [BACKUP] Updating existing backup file...');
        final fileId = existingFiles.files!.first.id!;
        print('📝 [BACKUP] File ID to update: $fileId');

        final updatedFile = await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );

        print(
            '✅ [BACKUP] Backup updated successfully! New file ID: ${updatedFile.id}');
      } else {
        // Create new backup file
        print('📝 [BACKUP] Creating new backup file...');
        final file = drive.File();
        file.name = backupFileName;
        file.parents = [folderId];
        file.mimeType = 'application/json';

        print(
            '📝 [BACKUP] File metadata: name=$backupFileName, parent=$folderId, mimeType=application/json');

        final createdFile = await driveApi.files.create(
          file,
          uploadMedia: media,
        );

        print(
            '✅ [BACKUP] Backup created successfully! New file ID: ${createdFile.id}');
      }

      // Verify the backup was created/updated
      print('🔍 [BACKUP] Verifying backup...');
      final verifyFiles = await driveApi.files.list(
        q: "name='$backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, size, modifiedTime)',
      );

      if (verifyFiles.files != null && verifyFiles.files!.isNotEmpty) {
        final backupFile = verifyFiles.files!.first;
        print('✅ [BACKUP] Verification successful!');
        print('✅ [BACKUP] File name: ${backupFile.name}');
        print('✅ [BACKUP] File ID: ${backupFile.id}');
        print('✅ [BACKUP] File size: ${backupFile.size}');
        print('✅ [BACKUP] Modified time: ${backupFile.modifiedTime}');
      } else {
        print('❌ [BACKUP] Verification failed - backup file not found!');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      print('❌ [BACKUP] Error backing up to Google Drive: $e');
      print('❌ [BACKUP] Stack trace: $stackTrace');
      return false;
    }
  }

  // Restore expenses from Google Drive
  Future<Map<String, dynamic>?> restoreExpenses() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('Failed to get Drive API');
        return null;
      }

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        print('Failed to get/create folder');
        return null;
      }

      // Find backup file
      final fileList = await driveApi.files.list(
        q: "name='$backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        print('No backup file found');
        return null;
      }

      final fileId = fileList.files!.first.id!;

      // Download file content
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dataStream = media.stream;
      final data = await dataStream.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );

      final jsonString = utf8.decode(data);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      final expensesJson = backupData['expenses'] as List<dynamic>;
      final expenses = expensesJson
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();

      final monthlyBudget = backupData['monthlyBudget'] as double?;

      print(
          'Restore successful: ${expenses.length} expenses, budget: $monthlyBudget');
      return {
        'expenses': expenses,
        'monthlyBudget': monthlyBudget,
      };
    } catch (e) {
      print('Error restoring from Google Drive: $e');
      return null;
    }
  }

  // Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) return null;

      final fileList = await driveApi.files.list(
        q: "name='$backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.modifiedTime;
      }

      return null;
    } catch (e) {
      print('Error getting last backup time: $e');
      return null;
    }
  }

  // Delete backup files permanently from Google Drive - FAST VERSION
  Future<bool> deleteAllBackupFiles() async {
    try {
      print(
          'Starting FAST permanent deletion of all backup files from Google Drive...');
      final stopwatch = Stopwatch()..start();

      final driveApi = await _getDriveApi().timeout(const Duration(seconds: 1));
      if (driveApi == null) {
        print(
            'Failed to get Drive API - user might not be signed in (${stopwatch.elapsedMilliseconds}ms)');
        return false;
      }

      print('Getting app folder... (${stopwatch.elapsedMilliseconds}ms)');
      final folderId = await _getOrCreateAppFolder(driveApi)
          .timeout(const Duration(seconds: 3));
      if (folderId == null) {
        print('Failed to get app folder (${stopwatch.elapsedMilliseconds}ms)');
        return false;
      }
      print('Folder ID: $folderId (${stopwatch.elapsedMilliseconds}ms)');

      // Find all backup files in the app folder with timeout
      final fileList = await driveApi.files
          .list(
            q: "'$folderId' in parents and trashed=false",
            spaces: 'drive',
            $fields: 'files(id, name)',
          )
          .timeout(const Duration(seconds: 2));

      if (fileList.files == null || fileList.files!.isEmpty) {
        print(
            'No backup files found to delete (${stopwatch.elapsedMilliseconds}ms)');
        return true; // No files to delete is considered success
      }

      print(
          'Found ${fileList.files!.length} backup files to delete (${stopwatch.elapsedMilliseconds}ms)');

      // Delete all files in parallel with individual timeouts
      final deletionFutures = fileList.files!.map((file) async {
        try {
          print('Deleting file: ${file.name} (ID: ${file.id})');
          await driveApi.files
              .delete(file.id!)
              .timeout(const Duration(seconds: 2));
          print('✅ Deleted file: ${file.name}');
          return true;
        } catch (e) {
          print('❌ Failed to delete file ${file.name}: $e');
          return false;
        }
      });

      // Wait for all deletions to complete or timeout
      final results = await Future.wait(
        deletionFutures,
        eagerError: false,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Some deletions timed out - continuing in background');
          return fileList.files!.map((e) => false).toList();
        },
      );

      final successCount = results.where((result) => result == true).length;
      stopwatch.stop();

      print(
          '✅ FAST Google Drive deletion completed: $successCount/${fileList.files!.length} files deleted in ${stopwatch.elapsedMilliseconds}ms');

      // Return true if at least some files were deleted or if there were no files
      return successCount > 0 || fileList.files!.isEmpty;
    } catch (e, stackTrace) {
      print('❌ Error in FAST Google Drive deletion: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Ensure Google Drive is ready for new backups after data deletion
  Future<bool> ensureDriveReadyAfterDeletion() async {
    try {
      print('🔄 Ensuring Google Drive is ready for new backups...');

      // Refresh Google authentication to ensure valid credentials
      final authRefreshed = await _authService.refreshGoogleAuthentication();
      if (!authRefreshed) {
        print('❌ Failed to refresh Google authentication');
        return false;
      }

      // Test Drive API access with refreshed authentication
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('❌ Drive API not available after authentication refresh');
        return false;
      }

      // Ensure app folder exists
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        print('❌ Failed to ensure app folder exists');
        return false;
      }

      print('✅ Google Drive is ready for new backups (Folder ID: $folderId)');
      return true;
    } catch (e) {
      print('❌ Error ensuring Drive readiness: $e');
      return false;
    }
  }

  // Debug method to test Drive API connection
  Future<bool> testDriveConnection() async {
    try {
      print('🧪 [DEBUG] Testing Google Drive API connection...');

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('❌ [DEBUG] Failed to get Drive API');
        return false;
      }

      print('🧪 [DEBUG] Drive API obtained successfully');

      // Test basic API call
      try {
        final about = await driveApi.about.get($fields: 'user');
        print('✅ [DEBUG] Drive API test successful');
        print(
            '✅ [DEBUG] User: ${about.user?.displayName} (${about.user?.emailAddress})');
        return true;
      } catch (apiError) {
        print('❌ [DEBUG] Drive API test failed: $apiError');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Drive connection test error: $e');
      print('❌ [DEBUG] Stack trace: $stackTrace');
      return false;
    }
  }

  // Backup PDF file to Google Drive
  Future<bool> backupPdfFile({
    required String filePath,
    required String fileName,
  }) async {
    try {
      print('Starting PDF backup to Google Drive: $fileName');

      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        print('Failed to get Drive API - user might not be signed in');
        return false;
      }

      print('Getting or creating app folder...');
      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        print('Failed to get/create folder');
        return false;
      }
      print('Folder ID: $folderId');

      // Read the PDF file
      final file = File(filePath);
      if (!await file.exists()) {
        print('PDF file does not exist at path: $filePath');
        return false;
      }

      final fileBytes = await file.readAsBytes();
      print('PDF file size: ${fileBytes.length} bytes');

      final media = drive.Media(
        Stream.value(fileBytes),
        fileBytes.length,
      );

      print('Checking for existing PDF file...');
      // Check if file with same name exists
      final existingFiles = await driveApi.files.list(
        q: "name='$fileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file
        print('Updating existing PDF file...');
        final fileId = existingFiles.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
        print('✅ PDF updated successfully!');
      } else {
        // Create new PDF file
        print('Creating new PDF file...');
        final driveFile = drive.File();
        driveFile.name = fileName;
        driveFile.parents = [folderId];
        driveFile.mimeType = 'application/pdf';

        await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
        print('✅ PDF uploaded successfully!');
      }

      return true;
    } catch (e, stackTrace) {
      print('❌ Error backing up PDF to Google Drive: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}

// Custom HTTP client for Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
