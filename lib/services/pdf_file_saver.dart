import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart' show OpenFile, ResultType;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Saves generated PDFs where the user can find them, then opens them.
///
/// Works without "All files access" (MANAGE_EXTERNAL_STORAGE), which Google
/// Play does not allow for this kind of app:
/// - Android 10+: public Downloads folder via MediaStore (MainActivity.kt)
/// - Android 9 and older: Downloads with WRITE_EXTERNAL_STORAGE, which the
///   manifest only declares up to API 28
/// - otherwise: the app's own folder
class PdfFileSaver {
  static const MethodChannel _channel = MethodChannel('expensetracker/downloads');

  /// Returns where the file was saved when no viewer could open it (so the
  /// user can be told), or null when it was opened.
  static Future<String?> saveAndOpen(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>('saveToDownloads', {
          'bytes': bytes,
          'name': fileName,
          'mimeType': 'application/pdf',
        });
        return opened == true ? null : 'Download/$fileName';
      } on PlatformException catch (e) {
        // UNSUPPORTED (Android 9 and older) or a failed save: use a file path
        print('ℹ️ [PDF] MediaStore save not used: ${e.code} ${e.message}');
      } on MissingPluginException {
        // No activity attached (e.g. a background engine)
      }
    }

    final directory = await _fallbackDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    try {
      final result = await OpenFile.open(file.path);
      return result.type == ResultType.done ? null : directory.path;
    } catch (e) {
      return directory.path;
    }
  }

  static Future<Directory> _fallbackDirectory() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        final downloads = Directory('/storage/emulated/0/Download');
        if (await downloads.exists()) return downloads;
      }
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
      return getApplicationDocumentsDirectory();
    }
    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
    return await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
  }
}
