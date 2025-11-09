import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/diary_entry.dart';

/// Wraps common Hive operations for diary entries.
class DiaryRepository {
  DiaryRepository._();

  static const String boxName = 'diary_entries_box';
  static final DiaryRepository instance = DiaryRepository._();

  Box<DiaryEntry> get _box => Hive.box<DiaryEntry>(boxName);

  List<DiaryEntry> getAllEntries() {
    final entries = _box.values.toList();
    entries.sort(
      (a, b) => b.date.compareTo(a.date),
    );
    return entries;
  }

  Future<void> addEntry(DiaryEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  ValueListenable<Box<DiaryEntry>> listenable() {
    return _box.listenable();
  }
}
