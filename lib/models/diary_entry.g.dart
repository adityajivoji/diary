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
    final formatIndex = (fields[4] as int?) ?? DiaryEntryFormat.standard.index;
    final spreads = (fields[5] as List?)?.cast<NotebookSpread>() ?? const [];
    return DiaryEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      mood: Mood.values[fields[2] as int],
      content: fields[3] as String,
      format: DiaryEntryFormat.values[formatIndex],
      notebookSpreads: spreads,
      notebookAppearance: fields[6] as NotebookAppearance?,
    );
  }

  @override
  void write(BinaryWriter writer, DiaryEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.mood.index)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.format.index)
      ..writeByte(5)
      ..write(obj.notebookSpreads)
      ..writeByte(6)
      ..write(obj.notebookAppearance);
  }
}

class NotebookAttachmentAdapter extends TypeAdapter<NotebookAttachment> {
  @override
  final int typeId = 2;

  @override
  NotebookAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotebookAttachment(
      id: fields[0] as String,
      type: NotebookAttachmentType.values[fields[1] as int],
      path: fields[2] as String,
      caption: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotebookAttachment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type.index)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.caption);
  }
}

class NotebookSpreadAdapter extends TypeAdapter<NotebookSpread> {
  @override
  final int typeId = 3;

  @override
  NotebookSpread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final attachments =
        (fields[0] as List?)?.cast<NotebookAttachment>() ?? const [];
    return NotebookSpread(
      attachments: List<NotebookAttachment>.from(attachments),
      text: fields[1] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, NotebookSpread obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.attachments)
      ..writeByte(1)
      ..write(obj.text);
  }
}

class NotebookAppearanceAdapter extends TypeAdapter<NotebookAppearance> {
  @override
  final int typeId = 4;

  @override
  NotebookAppearance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotebookAppearance(
      pageColorValue: fields[0] as int? ?? 0xFFFFFFFF,
      lineColorValue: fields[1] as int? ?? 0xFF000000,
      coverColorValue: fields[2] as int? ?? 0xFF000000,
      fontFamily: fields[3] as String? ?? 'Roboto',
      coverImagePath: fields[4] as String?,
      attachmentBackgroundColorValue:
          fields[5] as int? ?? 0xFFF3F4FF,
      attachmentIconColorValue: fields[6] as int? ?? 0xFF4F46E5,
    );
  }

  @override
  void write(BinaryWriter writer, NotebookAppearance obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.pageColorValue)
      ..writeByte(1)
      ..write(obj.lineColorValue)
      ..writeByte(2)
      ..write(obj.coverColorValue)
      ..writeByte(3)
      ..write(obj.fontFamily)
      ..writeByte(4)
      ..write(obj.coverImagePath)
      ..writeByte(5)
      ..write(obj.attachmentBackgroundColorValue)
      ..writeByte(6)
      ..write(obj.attachmentIconColorValue);
  }
}
