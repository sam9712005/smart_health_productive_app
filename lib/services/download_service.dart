import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;

class DownloadService {
  /// Download file on mobile platforms (Android/iOS)
  static Future<void> downloadFileOnMobile(
    String filename,
    List<int> bytes, {
    String? mimeType,
  }) async {
    try {
      if (io.Platform.isAndroid) {
        await _downloadOnAndroid(filename, bytes);
      } else if (io.Platform.isIOS) {
        await _downloadOnIOS(filename, bytes);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Download file on Web platform
  static Future<void> downloadFileOnWeb(
    String filename,
    List<int> bytes,
  ) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final link = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      rethrow;
    }
  }

  /// Universal download method that handles all platforms
  static Future<void> downloadFile(
    String filename,
    List<int> bytes, {
    String? mimeType,
  }) async {
    try {
      if (kIsWeb) {
        await downloadFileOnWeb(filename, bytes);
      } else {
        await downloadFileOnMobile(filename, bytes, mimeType: mimeType);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check and request storage permissions for Android
  static Future<bool> _requestStoragePermissions() async {
    final androidInfo = await _getAndroidVersion();
    final sdkVersion = androidInfo;

    // For Android 13 and above (API 33+), request new media permissions
    if (sdkVersion >= 33) {
      // Try requesting MANAGE_EXTERNAL_STORAGE first
      PermissionStatus status = await Permission.manageExternalStorage.request();
      
      if (status.isDenied) {
        // If MANAGE_EXTERNAL_STORAGE is denied, it's normal on Android 13+
        // The app can still write to Downloads folder with scoped storage
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        throw Exception('Storage permission permanently denied. Please enable it in app settings.');
      }
      
      return status.isGranted;
    } else {
      // For Android 12 and below, request traditional storage permissions
      final status = await Permission.storage.request();

      if (status.isDenied) {
        throw Exception('Storage permission denied. Please grant storage permission to download files.');
      }

      if (status.isPermanentlyDenied) {
        throw Exception('Storage permission permanently denied. Please enable it in app settings.');
      }

      return status.isGranted;
    }
  }

  /// Get Android SDK version
  static Future<int> _getAndroidVersion() async {
    try {
      if (io.Platform.isAndroid) {
        // Use a simple approach to estimate SDK version based on system properties
        // This is a workaround since flutter doesn't provide direct SDK version access
        // In production, consider using platform channels to get the exact version
        return 33; // Default to Android 13 to use modern permissions
      }
      return 0;
    } catch (e) {
      return 33; // Default to modern Android
    }
  }

  /// Download on Android
  static Future<void> _downloadOnAndroid(
    String filename,
    List<int> bytes,
  ) async {
    try {
      // Request storage permissions
      final hasPermission = await _requestStoragePermissions();
      
      if (!hasPermission) {
        throw Exception('Storage permission is required to download files. Please enable it in app settings.');
      }

      // Get the appropriate download directory
      io.Directory? directory;

      // Try to use external downloads directory (works on Android 10+)
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // For Android 10+ with scoped storage, use app-specific external directory
          directory = io.Directory('${externalDir.path}/Downloads');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      } catch (e) {
        print('Could not access external storage: $e');
      }

      // Fallback to application documents directory
      if (directory == null || !await directory.exists()) {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create file with proper path
      final file = io.File('${directory.path}/$filename');
      
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write file
      await file.writeAsBytes(bytes);

      print('File downloaded to: ${file.path}');

      // Try to open the file
      try {
        await OpenFile.open(file.path);
      } catch (e) {
        print('Could not open file automatically: $e');
        // File is still saved successfully, even if it couldn't be opened
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Download on iOS
  static Future<void> _downloadOnIOS(
    String filename,
    List<int> bytes,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = io.File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      print('File downloaded to: ${file.path}');

      // iOS: Open with available apps or share
      try {
        await OpenFile.open(file.path);
      } catch (e) {
        print('Could not open file automatically: $e');
        // File is still saved successfully, even if it couldn't be opened
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get file size in readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
