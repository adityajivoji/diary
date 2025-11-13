import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/diary_repository.dart';
import '../data/mood_repository.dart';
import '../models/diary_entry.dart';
import '../models/custom_mood.dart';
import '../widgets/add_mood_dialog.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/mood_selector.dart';
import '../widgets/notebook_editor.dart';
import '../widgets/theme_selector_action.dart';

/// Form screen for creating or editing a diary entry.
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({this.entry, super.key});

  final DiaryEntry? entry;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DiaryRepository _repository = DiaryRepository.instance;
  final MoodRepository _moodRepository = MoodRepository.instance;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late DateTime _selectedDate;
  late NotebookAppearance _notebookAppearance;
  DiaryEntryFormat _format = DiaryEntryFormat.standard;
  List<NotebookSpread> _notebookSpreads = <NotebookSpread>[];
  List<Mood> _selectedMoods = <Mood>[];
  bool _showNotebookExtras = true;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _format = entry?.format ?? DiaryEntryFormat.standard;
    final initialContent = entry?.content ?? '';
    final contentParts = _splitEntryContent(initialContent);
    _titleController = TextEditingController(text: contentParts['title']!);
    _contentController = TextEditingController(text: contentParts['body']!);
    _tagsController =
        TextEditingController(text: _formatTags(entry?.tags ?? const []));
    if (_format == DiaryEntryFormat.notebook &&
        _titleController.text.isEmpty &&
        initialContent.isNotEmpty) {
      _titleController.text = initialContent.trim();
    }
    _selectedDate = entry?.date ?? DateTime.now();
    _selectedMoods =
        List<Mood>.from(entry?.moods ?? <Mood>[entry?.mood ?? Mood.happy]);
    if (_format == DiaryEntryFormat.notebook && entry != null) {
      _notebookSpreads = entry.notebookSpreads.isEmpty
          ? <NotebookSpread>[NotebookSpread()]
          : entry.notebookSpreads
              .map(
                (spread) => NotebookSpread(
                  attachments: spread.attachments
                      .map((attachment) => attachment.copyWith())
                      .toList(),
                  text: spread.text,
                ),
              )
              .toList();
      _notebookAppearance =
          entry.notebookAppearance ?? NotebookAppearance.defaults();
      if (_contentController.text.isEmpty && _notebookSpreads.isNotEmpty) {
        _contentController.text = _notebookSpreads.first.text;
      }
    } else {
      _notebookSpreads = <NotebookSpread>[NotebookSpread()];
      _notebookAppearance = NotebookAppearance.defaults();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleModeChange(DiaryEntryFormat format) {
    if (format == _format) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (format == DiaryEntryFormat.notebook) {
        final text = _composePlainEntryText();
        if (text.isNotEmpty) {
          if (_notebookSpreads.isEmpty) {
            _notebookSpreads = <NotebookSpread>[NotebookSpread(text: text)];
          } else {
            _notebookSpreads[0] = _notebookSpreads[0].copyWith(text: text);
          }
        }
      } else if (_format == DiaryEntryFormat.notebook &&
          _notebookSpreads.isNotEmpty) {
        final firstText = _notebookSpreads.first.text.trim();
        if (firstText.isNotEmpty) {
          final parts = _splitEntryContent(firstText);
          _titleController.text = parts['title']!;
          _contentController.text = parts['body']!;
        }
      }
      _format = format;
    });
  }

  void _handleNotebookChanged(NotebookEditorValue value) {
    setState(() {
      _notebookSpreads = value.spreads;
      _notebookAppearance = value.appearance;
    });
  }

  Map<String, String> _splitEntryContent(String text) =>
      DiaryEntry.splitDiaryContent(text);

  String _composePlainEntryText() {
    final title = _titleController.text.trim();
    final body = _contentController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      return '';
    }
    if (title.isEmpty) {
      return body;
    }
    if (body.isEmpty) {
      return title;
    }
    return '$title\n\n$body';
  }

  String _composeEntryContent() {
    final title = _titleController.text.trim();
    final body = _contentController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      return '';
    }
    if (title.isEmpty) {
      return body;
    }

    final buffer = StringBuffer(DiaryEntry.titleStartToken)
      ..write(title)
      ..write(DiaryEntry.titleEndToken);

    if (body.isNotEmpty) {
      buffer.write('\n');
      buffer.write(body);
    }

    return buffer.toString();
  }

  List<String> _parseTags(String input) {
    final rawTags = input.split(RegExp(r'[,\n]'));
    final seen = <String>{};
    final result = <String>[];
    for (final raw in rawTags) {
      final tag = raw.trim();
      if (tag.isEmpty) continue;
      final normalized = tag.toLowerCase();
      if (seen.add(normalized)) {
        result.add(tag);
      }
    }
    return result;
  }

  String _formatTags(List<String> tags) {
    if (tags.isEmpty) return '';
    return tags.join(', ');
  }

  Future<void> _handleDeleteMood(Mood mood) async {
    if (!mood.isCustom) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete mood'),
          content: Text(
            'Are you sure you want to delete "${mood.label}"? '
            'Existing entries will keep their saved emoji and label.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await _moodRepository.deleteCustomMood(mood.id);
      if (!mounted) return;
      if (_selectedMoods.any((selected) => selected.id == mood.id)) {
        final replacementMoods = _moodRepository.getAllMoods();
        setState(() {
          _selectedMoods = _selectedMoods
              .where((selected) => selected.id != mood.id)
              .map((selected) => replacementMoods.firstWhere(
                    (moodOption) => moodOption.id == selected.id,
                    orElse: () => selected,
                  ))
              .toList(growable: false);
          if (_selectedMoods.isEmpty && replacementMoods.isNotEmpty) {
            _selectedMoods = <Mood>[replacementMoods.first];
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${mood.label}".')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete that mood. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleEditMood(Mood mood) async {
    if (!mood.isCustom) {
      return;
    }
    final updatedMood = await showDialog<Mood>(
      context: context,
      builder: (context) => AddMoodDialog(initialMood: mood),
    );
    if (!mounted || updatedMood == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated "${updatedMood.label}".')),
    );
  }

  Widget _buildEntryMetaSection(
    BuildContext context, {
    required bool isNotebook,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final outlineColor = onSurface.withValues(alpha: 0.28);
    final infoText = isNotebook
        ? 'Notebook mode lets you pair your writing with photos, drawings and audio on a double-page spread.'
        : 'Diary mode keeps things simple with a single flowing page for your thoughts.';
    final titleHint = isNotebook
        ? 'Give this notebook entry a short title'
        : 'Give this diary entry a short title';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey(
              isNotebook ? 'notebook-title-field' : 'diary-title-field'),
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: titleHint,
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Text(
          'Date',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_rounded),
          label: Text(_dateLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: onSurface,
            side: BorderSide(color: outlineColor),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Choose a mood',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<Box<CustomMood>>(
          valueListenable: _moodRepository.listenable(),
          builder: (context, _, __) {
            final moods = _moodRepository.getAllMoods();
            final moodById = {for (final mood in moods) mood.id: mood};
            var selection = _selectedMoods
                .map((selected) => moodById[selected.id])
                .whereType<Mood>()
                .toList(growable: false);
            if (selection.isEmpty && moods.isNotEmpty) {
              selection = <Mood>[moods.first];
            }
            if (!listEquals(selection, _selectedMoods)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedMoods = selection;
                });
              });
            }
            return MoodSelector(
              moods: moods,
              selectedMoods: selection,
              multiSelect: true,
              onSelectedMoodsChanged: (updated) {
                setState(() {
                  _selectedMoods = updated.isEmpty && moods.isNotEmpty
                      ? <Mood>[moods.first]
                      : updated;
                });
              },
              onDeleteMood: _handleDeleteMood,
              onEditMood: _handleEditMood,
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          infoText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tags',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags',
            hintText: 'Add tags separated by commas',
            helperText: 'Examples: travel, gratitude, weekend',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final bool isDark = theme.brightness == Brightness.dark;
    final selectedFill = isDark
        ? colorScheme.secondary.withValues(alpha: 0.35)
        : colorScheme.secondary.withValues(alpha: 0.2);

    return ToggleButtons(
      borderRadius: BorderRadius.circular(18),
      color: onSurface.withValues(alpha: 0.7),
      selectedColor: colorScheme.onSecondary,
      fillColor: selectedFill,
      borderColor: onSurface.withValues(alpha: 0.25),
      selectedBorderColor: colorScheme.secondary,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      isSelected: [
        _format == DiaryEntryFormat.standard,
        _format == DiaryEntryFormat.notebook,
      ],
      onPressed: (index) {
        final selected =
            index == 0 ? DiaryEntryFormat.standard : DiaryEntryFormat.notebook;
        _handleModeChange(selected);
      },
      constraints: const BoxConstraints(minHeight: 44, minWidth: 140),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded),
              SizedBox(width: 8),
              Text('Flow'),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded),
              SizedBox(width: 8),
              Text('Notebook'),
            ],
          ),
        ),
      ],
    );
  }

  List<Mood> get _resolvedMoods =>
      _selectedMoods.isNotEmpty ? _selectedMoods : <Mood>[Mood.happy];

  String get _dateLabel =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _entryDetailsSummary {
    final titleText = _titleController.text.trim();
    final bodyText = _contentController.text.trim();
    final moods = _resolvedMoods;
    final primaryMood = moods.first;
    final moodSummary = moods.length > 1
        ? '${primaryMood.emoji} ${primaryMood.label} +${moods.length - 1} more'
        : '${primaryMood.emoji} ${primaryMood.label}';
    final bool usesNotebook = _format == DiaryEntryFormat.notebook;

    String titleLabel;
    if (titleText.isNotEmpty) {
      titleLabel = titleText.replaceAll('\n', ' ');
    } else if (bodyText.isNotEmpty) {
      final firstLine = bodyText.split('\n').first.trim();
      if (firstLine.isEmpty) {
        titleLabel = usesNotebook ? 'Untitled notebook' : 'Diary entry';
      } else {
        titleLabel = firstLine;
      }
    } else {
      titleLabel = usesNotebook ? 'Untitled notebook' : 'Diary entry';
    }

    return '$titleLabel • $_dateLabel • $moodSummary';
  }

  Widget _buildStandardLayout(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('standard-layout'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeSelector(context),
          const SizedBox(height: 20),
          CollapsibleSection(
            title: 'Diary details',
            subtitle: _entryDetailsSummary,
            showSubtitleWhenExpanded: false,
            child: _buildEntryMetaSection(context, isNotebook: false),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('standard-content-field'),
            controller: _contentController,
            minLines: 10,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Dear diary...',
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (_format == DiaryEntryFormat.notebook) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return 'Tell your diary something sweet first.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saveEntry,
            icon: const Icon(Icons.save_rounded),
            label: Text(_isEditing ? 'Update Diary' : 'Save Diary'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookLayout(BuildContext context) {
    return Column(
      key: const ValueKey('notebook-layout'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _showNotebookExtras
                ? Column(
                    key: const ValueKey('notebook-toolbar'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeSelector(context),
                      const SizedBox(height: 12),
                      CollapsibleSection(
                        title: 'Notebook details',
                        subtitle: _entryDetailsSummary,
                        showSubtitleWhenExpanded: false,
                        child:
                            _buildEntryMetaSection(context, isNotebook: true),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NotebookEditor(
              initialSpreads: _notebookSpreads,
              initialAppearance: _notebookAppearance,
              onChanged: _handleNotebookChanged,
              footer: _buildNotebookExtrasToggle(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: FilledButton.icon(
            onPressed: _saveEntry,
            icon: const Icon(Icons.save_rounded),
            label: Text(_isEditing ? 'Update Diary' : 'Save Diary'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEntry() async {
    if (_format == DiaryEntryFormat.standard &&
        !_formKey.currentState!.validate()) {
      return;
    }

    final moods = _resolvedMoods;
    var content = _composeEntryContent();
    List<NotebookSpread> spreads = const [];
    NotebookAppearance? appearance;
    final tags = _parseTags(_tagsController.text);

    if (_format == DiaryEntryFormat.notebook) {
      final hasContent = _notebookSpreads.any(
        (spread) =>
            spread.text.trim().isNotEmpty || spread.attachments.isNotEmpty,
      );
      if (!hasContent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Add text, images, or audio before saving your notebook.'),
          ),
        );
        return;
      }
      spreads = _notebookSpreads
          .map(
            (spread) => NotebookSpread(
              attachments: spread.attachments
                  .map((attachment) => attachment.copyWith())
                  .toList(),
              text: spread.text,
            ),
          )
          .toList();
      final title = _titleController.text.trim();
      final summary = spreads.first.text.trim();
      if (title.isNotEmpty) {
        content = title;
      } else if (summary.isNotEmpty) {
        content = summary;
      } else if (content.isEmpty) {
        content = 'Notebook entry';
      }
      appearance = _notebookAppearance;
    }

    final entry = (_isEditing ? widget.entry! : null)?.copyWith(
          date: _selectedDate,
          moods: moods,
          content: content,
          format: _format,
          notebookSpreads: spreads,
          notebookAppearance: appearance,
          clearNotebookAppearance: appearance == null,
          tags: tags,
        ) ??
        DiaryEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: _selectedDate,
          moods: moods,
          content: content,
          format: _format,
          notebookSpreads: spreads,
          notebookAppearance: appearance,
          tags: tags,
        );

    if (_isEditing) {
      await _repository.updateEntry(entry);
    } else {
      await _repository.addEntry(entry);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleNotebookExtras() {
    setState(() {
      _showNotebookExtras = !_showNotebookExtras;
    });
  }

  Widget _buildNotebookExtrasToggle(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _toggleNotebookExtras,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
        ),
        icon: Icon(
          _showNotebookExtras
              ? Icons.unfold_less_rounded
              : Icons.unfold_more_rounded,
        ),
        label: Text(_showNotebookExtras ? 'Minimize' : 'Maximize'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _format == DiaryEntryFormat.standard
          ? _buildStandardLayout(context)
          : _buildNotebookLayout(context),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Update Diary' : 'New Diary'),
        actions: [
          const ThemeSelectorAction(),
          IconButton(
            onPressed: _saveEntry,
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save entry',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _NotebookToolbar extends StatefulWidget {
  const _NotebookToolbar({
    required this.modeSelector,
    required this.detailsSummary,
    required this.metaSection,
    required this.infoStyle,
  });

  final Widget modeSelector;
  final String detailsSummary;
  final Widget metaSection;
  final TextStyle? infoStyle;

  @override
  State<_NotebookToolbar> createState() => _NotebookToolbarState();
}

class _NotebookToolbarState extends State<_NotebookToolbar> {
  bool _showDetails = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showDetails) widget.modeSelector,
        if (_showDetails) const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: !_showDetails
              ? const SizedBox.shrink()
              : Column(
                  key: const ValueKey('notebook-details'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CollapsibleSection(
                      title: 'Notebook details',
                      subtitle: widget.detailsSummary,
                      showSubtitleWhenExpanded: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.metaSection,
                          const SizedBox(height: 12),
                          Text(
                            'Notebook mode lets you pair your writing with photos, drawings and audio on a double-page spread.',
                            style: widget.infoStyle?.copyWith(
                              color: onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: onSurface,
            ),
            icon: Icon(
              _showDetails
                  ? Icons.unfold_less_rounded
                  : Icons.unfold_more_rounded,
            ),
            label: Text(_showDetails ? 'Minimize' : 'Maximize'),
          ),
        ),
      ],
    );
  }
}
