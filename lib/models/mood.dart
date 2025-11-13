import 'package:flutter/foundation.dart';

/// Represents a selectable mood for diary entries.
@immutable
class Mood {
  const Mood({
    required this.id,
    required this.emoji,
    required this.label,
    this.isCustom = false,
  });

  final String id;
  final String emoji;
  final String label;
  final bool isCustom;

  static const Mood happy = Mood(id: 'happy', emoji: '😊', label: 'Joyful');
  static const Mood sad = Mood(id: 'sad', emoji: '😢', label: 'Blue');
  static const Mood angry = Mood(id: 'angry', emoji: '😡', label: 'Frustrated');
  static const Mood love = Mood(id: 'love', emoji: '❤️', label: 'Loved');
  static const Mood calm = Mood(id: 'calm', emoji: '😌', label: 'Calm');
  static const Mood sparkling =
      Mood(id: 'sparkling', emoji: '✨', label: 'Inspired');

  static const List<Mood> defaults = <Mood>[
    happy,
    sad,
    angry,
    love,
    calm,
    sparkling,
  ];

  Mood copyWith({
    String? emoji,
    String? label,
  }) {
    return Mood(
      id: id,
      emoji: emoji ?? this.emoji,
      label: label ?? this.label,
      isCustom: isCustom,
    );
  }

  static Mood? byId(
    String id, {
    Iterable<Mood> customMoods = const <Mood>[],
  }) {
    for (final mood in defaults) {
      if (mood.id == id) {
        return mood;
      }
    }
    for (final mood in customMoods) {
      if (mood.id == id) {
        return mood;
      }
    }
    return null;
  }

  Map<String, String> toMap() {
    return <String, String>{
      'id': id,
      'emoji': emoji,
      'label': label,
      'isCustom': isCustom ? 'true' : 'false',
    };
  }

  static Mood fromMap(Map<String, String> map) {
    return Mood(
      id: map['id'] ?? '',
      emoji: map['emoji'] ?? '',
      label: map['label'] ?? '',
      isCustom: map['isCustom'] == 'true',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mood && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Mood(id: $id, label: $label)';
}
