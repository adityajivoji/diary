import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'mood.dart';

export 'mood.dart';

part 'diary_entry.g.dart';

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
    required this.attachmentBackgroundColorValue,
    required this.attachmentIconColorValue,
  });

  final int pageColorValue;
  final int lineColorValue;
  final int coverColorValue;
  final String fontFamily;
  final String? coverImagePath;
  final int attachmentBackgroundColorValue;
  final int attachmentIconColorValue;

  Color get pageColor => Color(pageColorValue);
  Color get lineColor => Color(lineColorValue);
  Color get coverColor => Color(coverColorValue);
  Color get attachmentBackgroundColor => Color(attachmentBackgroundColorValue);
  Color get attachmentIconColor => Color(attachmentIconColorValue);

  NotebookAppearance copyWith({
    int? pageColorValue,
    int? lineColorValue,
    int? coverColorValue,
    String? fontFamily,
    String? coverImagePath,
    int? attachmentBackgroundColorValue,
    int? attachmentIconColorValue,
  }) {
    return NotebookAppearance(
      pageColorValue: pageColorValue ?? this.pageColorValue,
      lineColorValue: lineColorValue ?? this.lineColorValue,
      coverColorValue: coverColorValue ?? this.coverColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      attachmentBackgroundColorValue:
          attachmentBackgroundColorValue ?? this.attachmentBackgroundColorValue,
      attachmentIconColorValue:
          attachmentIconColorValue ?? this.attachmentIconColorValue,
    );
  }

  static NotebookAppearance defaults() {
    return const NotebookAppearance(
      pageColorValue: 0xFFFFFFFF,
      lineColorValue: 0xFF000000,
      coverColorValue: 0xFF000000,
      fontFamily: 'Roboto',
      attachmentBackgroundColorValue: 0xFFF3F4FF,
      attachmentIconColorValue: 0xFF4F46E5,
    );
  }
}

@HiveType(typeId: 1)
class DiaryEntry extends HiveObject {
  static const String titleStartToken = '{#title#}';
  static const String titleEndToken = '{#/title#}';

  static Map<String, String> splitDiaryContent(String content) {
    if (!content.startsWith(titleStartToken)) {
      return {'title': '', 'body': content};
    }
    final endIndex = content.indexOf(titleEndToken, titleStartToken.length);
    if (endIndex == -1) {
      return {'title': '', 'body': content};
    }
    final title = content.substring(titleStartToken.length, endIndex).trim();
    final body = content.substring(endIndex + titleEndToken.length).trimLeft();
    return {'title': title, 'body': body};
  }

  factory DiaryEntry({
    required String id,
    required DateTime date,
    Mood? mood,
    List<Mood>? moods,
    required String content,
    DiaryEntryFormat? format,
    List<NotebookSpread>? notebookSpreads,
    NotebookAppearance? notebookAppearance,
    List<String>? tags,
  }) {
    final resolvedMoods = _resolveMoods(
      mood: mood,
      moods: moods,
    );
    final primaryMood = resolvedMoods.first;
    final resolvedFormat = format ?? DiaryEntryFormat.standard;
    final resolvedSpreads = notebookSpreads != null
        ? List<NotebookSpread>.from(notebookSpreads)
        : <NotebookSpread>[];
    final resolvedTags = tags != null ? List<String>.from(tags) : <String>[];

    assert(
      !(resolvedFormat == DiaryEntryFormat.notebook && resolvedSpreads.isEmpty),
      'Notebook entries should include at least one spread.',
    );

    return DiaryEntry._internal(
      id: id,
      date: date,
      primaryMood: primaryMood,
      moods: resolvedMoods,
      content: content,
      entryFormat: resolvedFormat,
      spreads: resolvedSpreads,
      notebookAppearance: notebookAppearance,
      entryTags: resolvedTags,
    );
  }

  DiaryEntry._internal({
    required this.id,
    required this.date,
    required Mood primaryMood,
    required List<Mood> moods,
    required this.content,
    required DiaryEntryFormat entryFormat,
    required List<NotebookSpread> spreads,
    this.notebookAppearance,
    required List<String> entryTags,
  })  : moodId = primaryMood.id,
        moodLabel = primaryMood.label,
        moodEmoji = primaryMood.emoji,
        isCustomMood = primaryMood.isCustom,
        format = entryFormat,
        notebookSpreads = List<NotebookSpread>.unmodifiable(spreads),
        tags = List<String>.unmodifiable(entryTags),
        moodSnapshotMaps =
            List<Map<String, dynamic>>.unmodifiable(_serializeMoods(moods)),
        _moods = List<Mood>.unmodifiable(moods),
        assert(
          !(entryFormat == DiaryEntryFormat.notebook && spreads.isEmpty),
          'Notebook entries should include at least one spread.',
        );

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String moodId;

  @HiveField(8)
  final String moodLabel;

  @HiveField(9)
  final String moodEmoji;

  @HiveField(10)
  final bool isCustomMood;

  @HiveField(11)
  final List<Map<String, dynamic>> moodSnapshotMaps;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DiaryEntryFormat format;

  @HiveField(5)
  final List<NotebookSpread> notebookSpreads;

  @HiveField(6)
  final NotebookAppearance? notebookAppearance;

  @HiveField(7)
  final List<String> tags;

  final List<Mood> _moods;

  List<Mood> get moods => _moods;

  Mood get mood => _moods.first;

  bool get hasMultipleMoods => _moods.length > 1;

  bool get usesNotebook => format == DiaryEntryFormat.notebook;

  String get diaryTitle => splitDiaryContent(content)['title']!;

  String get diaryBody => splitDiaryContent(content)['body']!;

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

  String get resolvedTitle {
    String firstNonEmptyLine(String text) {
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
      return '';
    }

    final trimmedDiaryTitle = diaryTitle.trim();
    if (!usesNotebook) {
      if (trimmedDiaryTitle.isNotEmpty) {
        return trimmedDiaryTitle;
      }
      return firstNonEmptyLine(diaryBody);
    }

    if (trimmedDiaryTitle.isNotEmpty) {
      return trimmedDiaryTitle;
    }
    final notebookLine = firstNonEmptyLine(content);
    if (notebookLine.isNotEmpty) {
      return notebookLine;
    }
    if (notebookSpreads.isNotEmpty) {
      return firstNonEmptyLine(notebookSpreads.first.text);
    }
    return '';
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    Mood? mood,
    List<Mood>? moods,
    String? content,
    DiaryEntryFormat? format,
    List<NotebookSpread>? notebookSpreads,
    NotebookAppearance? notebookAppearance,
    bool clearNotebookAppearance = false,
    List<String>? tags,
  }) {
    final nextMoods =
        moods ?? (mood != null ? <Mood>[mood] : List<Mood>.from(this.moods));
    final nextNotebookAppearance = clearNotebookAppearance
        ? null
        : (notebookAppearance ?? this.notebookAppearance);
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      moods: nextMoods,
      content: content ?? this.content,
      format: format ?? this.format,
      notebookSpreads:
          notebookSpreads ?? List<NotebookSpread>.from(this.notebookSpreads),
      notebookAppearance: nextNotebookAppearance,
      tags: tags ?? List<String>.from(this.tags),
    );
  }
}

List<Mood> _resolveMoods({
  Mood? mood,
  List<Mood>? moods,
}) {
  final buffer = <Mood>[];
  final seen = <String>{};

  void addMood(Mood value) {
    if (seen.add(value.id)) {
      buffer.add(value);
    }
  }

  if (moods != null) {
    for (final item in moods) {
      addMood(item);
    }
  }
  if (buffer.isEmpty && mood != null) {
    addMood(mood);
  }
  if (buffer.isEmpty) {
    addMood(Mood.happy);
  }
  return buffer;
}

List<Map<String, dynamic>> _serializeMoods(List<Mood> moods) {
  return moods
      .map(
        (mood) => <String, dynamic>{
          'id': mood.id,
          'emoji': mood.emoji,
          'label': mood.label,
          'isCustom': mood.isCustom,
        },
      )
      .toList(growable: false);
}

List<Mood> _deserializeMoods(List<dynamic>? raw, Mood primary) {
  final seen = <String>{};
  final result = <Mood>[];

  void addMood(Mood value) {
    if (seen.add(value.id)) {
      result.add(value);
    }
  }

  addMood(primary);

  if (raw == null) {
    return result;
  }

  for (final item in raw) {
    if (item is Map) {
      final id = item['id'] as String? ?? primary.id;
      final fallback = Mood.byId(id) ?? primary;
      final emoji = item['emoji'] as String? ?? fallback.emoji;
      final label = item['label'] as String? ?? fallback.label;
      final isCustom = item['isCustom'] is bool
          ? item['isCustom'] as bool
          : fallback.isCustom;
      addMood(
        Mood(
          id: id,
          emoji: emoji,
          label: label,
          isCustom: isCustom,
        ),
      );
    }
  }

  if (result.isEmpty) {
    addMood(primary);
  }

  return result;
}
