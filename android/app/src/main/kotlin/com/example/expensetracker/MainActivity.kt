package com.example.expensetracker

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Saves files (PDF statements) to the public Downloads folder through
        // MediaStore, which needs no storage permission on Android 10+. This
        // replaces "All files access", which Google Play does not allow here.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "expensetracker/downloads")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.error("UNSUPPORTED", "MediaStore downloads need Android 10", null)
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val name = call.argument<String>("name")
                val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                if (bytes == null || name == null) {
                    result.error("BAD_ARGS", "bytes and name are required", null)
                    return@setMethodCallHandler
                }

                val resolver = contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                if (uri == null) {
                    result.error("SAVE_FAILED", "Could not create $name", null)
                    return@setMethodCallHandler
                }
                try {
                    resolver.openOutputStream(uri)?.use { it.write(bytes) }
                        ?: throw IllegalStateException("Could not write $name")
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    resolver.update(uri, values, null, null)
                } catch (e: Exception) {
                    resolver.delete(uri, null, null)
                    result.error("SAVE_FAILED", e.message, null)
                    return@setMethodCallHandler
                }

                // Open it in the user's PDF viewer; false if none is installed
                val opened = try {
                    startActivity(Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    })
                    true
                } catch (e: ActivityNotFoundException) {
                    false
                }
                result.success(opened)
            }
    }
}
