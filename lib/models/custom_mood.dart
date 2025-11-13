import 'package:hive/hive.dart';

import 'mood.dart';

/// Persisted custom mood created by the user.
class CustomMood {
  const CustomMood({
    required this.id,
    required this.emoji,
    required this.label,
  });

  final String id;
  final String emoji;
  final String label;

  Mood toMood() {
    return Mood(
      id: id,
      emoji: emoji,
      label: label,
      isCustom: true,
    );
  }
}

class CustomMoodAdapter extends TypeAdapter<CustomMood> {
  @override
  final int typeId = 5;

  @override
  CustomMood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomMood(
      id: fields[0] as String,
      emoji: fields[1] as String,
      label: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CustomMood obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.emoji)
      ..writeByte(2)
      ..write(obj.label);
  }
}
