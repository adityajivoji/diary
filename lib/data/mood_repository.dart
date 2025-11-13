import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/custom_mood.dart';
import '../models/mood.dart';

/// Provides access to default and custom moods.
class MoodRepository {
  MoodRepository._();

  static const String boxName = 'custom_moods_box';
  static final MoodRepository instance = MoodRepository._();

  Box<CustomMood> get _box => Hive.box<CustomMood>(boxName);

  List<Mood> getAllMoods() {
    final custom = _box.values.map((mood) => mood.toMood());
    return <Mood>[
      ...Mood.defaults,
      ...custom,
    ];
  }

  ValueListenable<Box<CustomMood>> listenable() {
    return _box.listenable();
  }

  Mood? findMoodById(String id) {
    final mood = Mood.byId(id, customMoods: _box.values.map((m) => m.toMood()));
    return mood;
  }

  bool labelExists(String label) {
    final normalized = label.trim().toLowerCase();
    for (final mood in Mood.defaults) {
      if (mood.label.toLowerCase() == normalized) {
        return true;
      }
    }
    return _box.values.any(
      (mood) => mood.label.trim().toLowerCase() == normalized,
    );
  }

  Future<Mood> createCustomMood({
    required String emoji,
    required String label,
  }) async {
    final trimmedEmoji = emoji.trim();
    final trimmedLabel = label.trim();
    final id = _generateId(trimmedLabel);
    final customMood = CustomMood(
      id: id,
      emoji: trimmedEmoji,
      label: _titleCase(trimmedLabel),
    );
    await _box.put(customMood.id, customMood);
    return customMood.toMood();
  }

  String _generateId(String label) {
    final base = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp('-{2,}'), '-')
        .trim()
        .replaceAll(RegExp(r'^-|-$'), '');
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    if (base.isEmpty) {
      return 'custom-$suffix';
    }
    return 'custom-$base-$suffix';
  }

  String _titleCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    final words = input
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return input;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      buffer.write(word[0].toUpperCase());
      if (word.length > 1) {
        buffer.write(word.substring(1).toLowerCase());
      }
      if (i != words.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
