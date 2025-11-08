import 'package:hive/hive.dart';

part 'diary_entry.g.dart';

/// Emoji moods available for entries.
enum Mood {
  happy('😊', 'Joyful'),
  sad('😢', 'Blue'),
  angry('😡', 'Frustrated'),
  love('❤️', 'Loved'),
  calm('😌', 'Calm'),
  sparkling('✨', 'Inspired');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;
}

@HiveType(typeId: 1)
class DiaryEntry extends HiveObject {
  DiaryEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.content,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final Mood mood;

  @HiveField(3)
  final String content;

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    Mood? mood,
    String? content,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      content: content ?? this.content,
    );
  }
}
