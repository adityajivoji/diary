import 'dart:io';

import 'package:flutter/services.dart';

/// Handles security-scoped bookmark operations on macOS.
class SecurityScopedBookmarkManager {
  SecurityScopedBookmarkManager._();

  static const MethodChannel _channel =
      MethodChannel('sharu_diary/security_scoped_bookmarks');

  static Future<String?> createBookmark(String path) async {
    if (!Platform.isMacOS) {
      return null;
    }
    final bookmark =
        await _channel.invokeMethod<String>('createBookmark', {'path': path});
    return bookmark;
  }

  static Future<SecurityScopedAccessResult?> startAccess(String bookmark) async {
    if (!Platform.isMacOS) {
      return null;
    }

    final result = await _channel.invokeMapMethod<String, dynamic>(
      'startAccessingBookmark',
      {'bookmark': bookmark},
    );
    if (result == null) {
      return null;
    }

    final path = result['path'] as String?;
    if (path == null) {
      return null;
    }
    final updatedBookmark = result['bookmark'] as String?;
    return SecurityScopedAccessResult(path: path, bookmark: updatedBookmark);
  }

  static Future<void> stopAccess(String bookmark) async {
    if (!Platform.isMacOS) {
      return;
    }
    await _channel.invokeMethod<void>(
      'stopAccessingBookmark',
      {'bookmark': bookmark},
    );
  }
}

class SecurityScopedAccessResult {
  SecurityScopedAccessResult({
    required this.path,
    this.bookmark,
  });

  final String path;
  final String? bookmark;
}
