import 'package:flutter/material.dart';
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

/// The type of entry the user chose when composing.
enum DiaryEntryFormat {
  standard,
  notebook,
}

/// Type of attachment that lives on the blank (left) side page.
enum NotebookAttachmentType {
  image,
  audio,
}

/// Attachment that can be added to the blank page of a notebook spread.
class NotebookAttachment {
  const NotebookAttachment({
    required this.id,
    required this.type,
    required this.path,
    this.caption,
  });

  final String id;
  final NotebookAttachmentType type;
  final String path;
  final String? caption;

  NotebookAttachment copyWith({
    String? id,
    NotebookAttachmentType? type,
    String? path,
    String? caption,
  }) {
    return NotebookAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      path: path ?? this.path,
      caption: caption ?? this.caption,
    );
  }
}

/// Represents a two-page spread in the notebook editor.
class NotebookSpread {
  NotebookSpread({
    List<NotebookAttachment>? attachments,
    String? text,
  })  : attachments = attachments ?? <NotebookAttachment>[],
        text = text ?? '';

  final List<NotebookAttachment> attachments;
  final String text;

  NotebookSpread copyWith({
    List<NotebookAttachment>? attachments,
    String? text,
  }) {
    return NotebookSpread(
      attachments:
          attachments ?? List<NotebookAttachment>.from(this.attachments),
      text: text ?? this.text,
    );
  }
}

/// Controls the appearance of the notebook (page, lines, cover, etc).
class NotebookAppearance {
  const NotebookAppearance({
    required this.pageColorValue,
    required this.lineColorValue,
    required this.coverColorValue,
    required this.fontFamily,
    this.coverImagePath,
  });

  final int pageColorValue;
  final int lineColorValue;
  final int coverColorValue;
  final String fontFamily;
  final String? coverImagePath;

  Color get pageColor => Color(pageColorValue);
  Color get lineColor => Color(lineColorValue);
  Color get coverColor => Color(coverColorValue);

  NotebookAppearance copyWith({
    int? pageColorValue,
    int? lineColorValue,
    int? coverColorValue,
    String? fontFamily,
    String? coverImagePath,
  }) {
    return NotebookAppearance(
      pageColorValue: pageColorValue ?? this.pageColorValue,
      lineColorValue: lineColorValue ?? this.lineColorValue,
      coverColorValue: coverColorValue ?? this.coverColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }

  static NotebookAppearance defaults() {
    return const NotebookAppearance(
      pageColorValue: 0xFFFFFFFF,
      lineColorValue: 0xFF000000,
      coverColorValue: 0xFF000000,
      fontFamily: 'Roboto',
    );
  }
}

@HiveType(typeId: 1)
class DiaryEntry extends HiveObject {
  DiaryEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.content,
    DiaryEntryFormat? format,
    List<NotebookSpread>? notebookSpreads,
    this.notebookAppearance,
  })  : format = format ?? DiaryEntryFormat.standard,
        notebookSpreads = notebookSpreads ?? <NotebookSpread>[],
        assert(
          !((format ?? DiaryEntryFormat.standard) == DiaryEntryFormat.notebook &&
              (notebookSpreads ?? <NotebookSpread>[]).isEmpty),
          'Notebook entries should include at least one spread.',
        );

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final Mood mood;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DiaryEntryFormat format;

  @HiveField(5)
  final List<NotebookSpread> notebookSpreads;

  @HiveField(6)
  final NotebookAppearance? notebookAppearance;

  bool get usesNotebook => format == DiaryEntryFormat.notebook;

  String get notebookSummary {
    if (!usesNotebook || notebookSpreads.isEmpty) {
      return content;
    }
    final firstSpreadText = notebookSpreads.first.text.trim();
    if (firstSpreadText.isEmpty) {
      return content;
    }
    return firstSpreadText;
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    Mood? mood,
    String? content,
    DiaryEntryFormat? format,
    List<NotebookSpread>? notebookSpreads,
    NotebookAppearance? notebookAppearance,
    bool clearNotebookAppearance = false,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      content: content ?? this.content,
      format: format ?? this.format,
      notebookSpreads:
          notebookSpreads ?? List<NotebookSpread>.from(this.notebookSpreads),
      notebookAppearance: clearNotebookAppearance
          ? null
          : (notebookAppearance ?? this.notebookAppearance),
    );
  }
}
