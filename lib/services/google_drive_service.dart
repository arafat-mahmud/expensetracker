import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
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
      print('Getting Google account for Drive API...');
      GoogleSignInAccount? account =
          await _authService.getGoogleSignInAccount();

      // If no account, user needs to sign in first
      if (account == null) {
        print('❌ No Google account available - user needs to sign in first');
        return null;
      }

      print('✅ Using Google account: ${account.email}');

      // Get authorization headers for Drive API
      // Set promptIfNecessary to false to prevent repeated account picker dialogs
      final authHeaders =
          await account.authorizationClient.authorizationHeaders([
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive.appdata',
      ], promptIfNecessary: false);

      if (authHeaders == null) {
        print(
            'Failed to get authorization headers - user may need to re-authenticate');
        return null;
      }

      print('Got authorization headers, creating Drive API client...');
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      print('✅ Drive API authenticated successfully for: ${account.email}');
      return driveApi;
    } catch (e, stackTrace) {
      print('❌ Error getting Drive API: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Find or create app folder
  Future<String?> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    try {
      // Search for existing folder
      final fileList = await driveApi.files.list(
        q: "name='$appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Create new folder
      final folder = drive.File();
      folder.name = appFolderName;
      folder.mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Error creating/finding app folder: $e');
      return null;
    }
  }

  // Backup expenses to Google Drive
  Future<bool> backupExpenses(List<Expense> expenses) async {
    try {
      print('Starting Google Drive backup for ${expenses.length} expenses...');

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

      // Prepare backup data
      final backupData = {
        'backupDate': DateTime.now().toIso8601String(),
        'userId': _authService.getUserId(),
        'userEmail': _authService.getUserEmail(),
        'expensesCount': expenses.length,
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

      final jsonData = jsonEncode(backupData);
      print('Backup data size: ${jsonData.length} bytes');

      final media = drive.Media(
        Stream.value(utf8.encode(jsonData)),
        jsonData.length,
      );

      print('Checking for existing backup file...');
      // Check if backup file exists
      final existingFiles = await driveApi.files.list(
        q: "name='$backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing file
        print('Updating existing backup file...');
        final fileId = existingFiles.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
        print('✅ Backup updated successfully!');
      } else {
        // Create new backup file
        print('Creating new backup file...');
        final file = drive.File();
        file.name = backupFileName;
        file.parents = [folderId];
        file.mimeType = 'application/json';

        await driveApi.files.create(
          file,
          uploadMedia: media,
        );
        print('✅ Backup created successfully!');
      }

      return true;
    } catch (e, stackTrace) {
      print('❌ Error backing up to Google Drive: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Restore expenses from Google Drive
  Future<List<Expense>?> restoreExpenses() async {
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

      print('Restore successful: ${expenses.length} expenses');
      return expenses;
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
