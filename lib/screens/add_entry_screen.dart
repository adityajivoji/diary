import 'package:flutter/material.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';
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

  late final TextEditingController _contentController;
  late DateTime _selectedDate;
  late NotebookAppearance _notebookAppearance;
  DiaryEntryFormat _format = DiaryEntryFormat.standard;
  List<NotebookSpread> _notebookSpreads = <NotebookSpread>[];
  Mood? _selectedMood;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _contentController = TextEditingController(text: entry?.content ?? '');
    _selectedDate = entry?.date ?? DateTime.now();
    _selectedMood = entry?.mood ?? Mood.happy;
    _format = entry?.format ?? DiaryEntryFormat.standard;
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
    _contentController.dispose();
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
        final text = _contentController.text.trim();
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
          _contentController.text = firstText;
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
              Text('Default entry'),
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

  Widget _buildCommonMetaSection(BuildContext context) {
    final theme = Theme.of(context);
    final mood = _selectedMood ?? Mood.happy;
    final surfaceColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Mood: ${mood.emoji} ${mood.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MoodSelector(
          selectedMood: _selectedMood,
          onMoodSelected: (mood) =>
              setState(() => _selectedMood = mood ?? Mood.happy),
        ),
      ],
    );
  }

  Widget _buildNotebookMetaSection(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final outlineColor = onSurface.withValues(alpha: 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notebook title',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('notebook-title-field'),
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Give this notebook entry a short title',
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
          label: Text(
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          ),
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
        MoodSelector(
          selectedMood: _selectedMood,
          onMoodSelected: (mood) =>
              setState(() => _selectedMood = mood ?? Mood.happy),
        ),
      ],
    );
  }

  Mood get _resolvedMood => _selectedMood ?? Mood.happy;

  String get _dateLabel =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _notebookDetailsSummary {
    final title = _contentController.text.trim();
    final titleLabel =
        title.isEmpty ? 'Untitled notebook' : title.replaceAll('\n', ' ');
    final mood = _resolvedMood;
    return '$titleLabel • $_dateLabel • ${mood.emoji} ${mood.label}';
  }

  Widget _buildStandardLayout(BuildContext context) {
    final mood = _resolvedMood;

    return SingleChildScrollView(
      key: const ValueKey('standard-layout'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeSelector(context),
          const SizedBox(height: 20),
          CollapsibleSection(
            title: 'Date & mood',
            subtitle: '$_dateLabel • ${mood.emoji} ${mood.label}',
            child: _buildCommonMetaSection(context),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeSelector(context),
              const SizedBox(height: 20),
              CollapsibleSection(
                title: 'Notebook details',
                subtitle: _notebookDetailsSummary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotebookMetaSection(context),
                    const SizedBox(height: 12),
                    Text(
                      'Notebook mode lets you pair your writing with photos, drawings and audio on a double-page spread.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NotebookEditor(
              initialSpreads: _notebookSpreads,
              initialAppearance: _notebookAppearance,
              onChanged: _handleNotebookChanged,
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

    final mood = _selectedMood ?? Mood.happy;
    var content = _contentController.text.trim();
    List<NotebookSpread> spreads = const [];
    NotebookAppearance? appearance;

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
      final title = content;
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
          mood: mood,
          content: content,
          format: _format,
          notebookSpreads: spreads,
          notebookAppearance: appearance,
          clearNotebookAppearance: appearance == null,
        ) ??
        DiaryEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: _selectedDate,
          mood: mood,
          content: content,
          format: _format,
          notebookSpreads: spreads,
          notebookAppearance: appearance,
        );

    if (_isEditing) {
      await _repository.updateEntry(entry);
    } else {
      await _repository.addEntry(entry);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
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
