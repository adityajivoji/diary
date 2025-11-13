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

  Future<void> refreshMoodSnapshots(Mood mood) async {
    final entriesNeedingUpdate = _box.values.where(
      (entry) => entry.moods.any((item) => item.id == mood.id),
    );
    for (final entry in entriesNeedingUpdate) {
      final updatedMoods = entry.moods
          .map(
            (current) => current.id == mood.id
                ? current.copyWith(
                    emoji: mood.emoji,
                    label: mood.label,
                  )
                : current,
          )
          .toList(growable: false);
      final updatedEntry = entry.copyWith(moods: updatedMoods);
      await _box.put(updatedEntry.id, updatedEntry);
    }
  }

  ValueListenable<Box<DiaryEntry>> listenable() {
    return _box.listenable();
  }
}
