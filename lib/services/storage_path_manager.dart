import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'security_scoped_bookmarks.dart';

/// Handles locating and persisting the Hive storage directory on macOS.
class StoragePathManager {
  StoragePathManager({SharedPreferences? preferences})
      : _preferencesFuture =
            preferences != null ? Future.value(preferences) : SharedPreferences.getInstance();

  static const String _prefsKey = 'macos_custom_storage_path';
  static const String _bookmarkPrefsKey = 'macos_custom_storage_bookmark';
  static const String _selectedFolderKey = 'macos_selected_folder_path';
  static const String _dataDirectoryName = 'PastelDiaryData';

  final Future<SharedPreferences> _preferencesFuture;
  String? _activeBookmark;

  Future<String?> loadSavedPath() async {
    final prefs = await _preferencesFuture;
    final cached = prefs.getString(_prefsKey);
    if (cached == null || cached.isEmpty) {
      return null;
    }

    if (!Platform.isMacOS) {
      final directory = Directory(cached);
      if (await directory.exists()) {
        return cached;
      }
      return null;
    }

    final bookmark = prefs.getString(_bookmarkPrefsKey);
    final selectedFolder = prefs.getString(_selectedFolderKey);
    if (bookmark == null ||
        bookmark.isEmpty ||
        selectedFolder == null ||
        selectedFolder.isEmpty) {
      await _clearStoredSelection(prefs);
      return null;
    }

    try {
      final accessResult = await SecurityScopedBookmarkManager.startAccess(bookmark);
      if (accessResult == null) {
        await _clearStoredSelection(prefs);
        return null;
      }

      final resolvedFolder = accessResult.path;
      _activeBookmark = accessResult.bookmark ?? bookmark;

      if (accessResult.bookmark != null &&
          accessResult.bookmark!.isNotEmpty &&
          accessResult.bookmark != bookmark) {
        await prefs.setString(_bookmarkPrefsKey, accessResult.bookmark!);
      }

      final hiveDirectory = Directory(p.join(resolvedFolder, _dataDirectoryName));
      if (!await hiveDirectory.exists()) {
        await hiveDirectory.create(recursive: true);
      }

      await prefs.setString(_selectedFolderKey, resolvedFolder);
      await prefs.setString(_prefsKey, hiveDirectory.path);

      return hiveDirectory.path;
    } on Exception {
      await releaseActiveBookmark();
      await _clearStoredSelection(prefs);
    }
    return null;
  }

  Future<String?> promptUserForDirectory() async {
    final selectedPath = await getDirectoryPath(confirmButtonText: 'Use Folder');
    if (selectedPath == null) {
      return null;
    }

    var folderPath = selectedPath;
    String? bookmarkToStore;

    if (Platform.isMacOS) {
      await releaseActiveBookmark();

      final bookmark = await SecurityScopedBookmarkManager.createBookmark(folderPath);
      if (bookmark == null || bookmark.isEmpty) {
        throw const FileSystemException(
          'Failed to create a security-scoped bookmark for the selected folder.',
        );
      }

      final accessResult = await SecurityScopedBookmarkManager.startAccess(bookmark);
      if (accessResult == null) {
        throw const FileSystemException(
          'Failed to access the selected folder with the created bookmark.',
        );
      }

      folderPath = accessResult.path;
      bookmarkToStore = accessResult.bookmark ?? bookmark;
      _activeBookmark = bookmarkToStore;
    } else {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    final hiveDirectory = Directory(p.join(folderPath, _dataDirectoryName));
    if (!await hiveDirectory.exists()) {
      await hiveDirectory.create(recursive: true);
    }

    await _persistSelection(
      hiveDirectory.path,
      bookmarkToStore,
      selectedFolderPath: folderPath,
    );
    return hiveDirectory.path;
  }

  Future<void> releaseActiveBookmark() async {
    if (!Platform.isMacOS) {
      return;
    }
    final bookmark = _activeBookmark;
    if (bookmark == null || bookmark.isEmpty) {
      return;
    }
    await SecurityScopedBookmarkManager.stopAccess(bookmark);
    _activeBookmark = null;
  }

  Future<void> _persistSelection(
    String hivePath,
    String? bookmark, {
    String? selectedFolderPath,
  }) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_prefsKey, hivePath);
    if (Platform.isMacOS) {
      if (selectedFolderPath != null && selectedFolderPath.isNotEmpty) {
        await prefs.setString(_selectedFolderKey, selectedFolderPath);
      }
      if (bookmark != null && bookmark.isNotEmpty) {
        await prefs.setString(_bookmarkPrefsKey, bookmark);
      } else {
        await prefs.remove(_bookmarkPrefsKey);
      }
    }
  }

  Future<void> _clearStoredSelection(SharedPreferences prefs) async {
    await prefs.remove(_prefsKey);
    await prefs.remove(_bookmarkPrefsKey);
    await prefs.remove(_selectedFolderKey);
  }
}
