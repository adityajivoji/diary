// GENERATED CODE - MANUALLY WRITTEN FOR TUTORIAL PURPOSES.

part of 'diary_entry.dart';

class DiaryEntryAdapter extends TypeAdapter<DiaryEntry> {
  @override
  final int typeId = 1;

  @override
  DiaryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiaryEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      mood: Mood.values[fields[2] as int],
      content: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DiaryEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.mood.index)
      ..writeByte(3)
      ..write(obj.content);
  }
}
