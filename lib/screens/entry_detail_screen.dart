import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';
import 'add_entry_screen.dart';
import '../widgets/notebook_viewer.dart';
import '../widgets/theme_selector_action.dart';

/// Shows a single diary entry in detail.
class EntryDetailScreen extends StatelessWidget {
  EntryDetailScreen({required this.entry, super.key})
      : _dateFormat = DateFormat.yMMMMEEEEd();

  final DiaryEntry entry;
  final DateFormat _dateFormat;

  @override
  Widget build(BuildContext context) {
    final repository = DiaryRepository.instance;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gradientStart = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.9);
    final gradientEnd = isDark
        ? scheme.surfaceContainerHigh.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.6);
    final contentBackground = isDark
        ? scheme.surfaceContainerHigh.withValues(alpha: 0.95)
        : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.05);

    return ValueListenableBuilder<Box<DiaryEntry>>(
      valueListenable: repository.listenable(),
      builder: (context, box, _) {
        final currentEntry = box.get(entry.id) ?? entry;
        final isNotebook = currentEntry.usesNotebook;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your memory'),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentEntry.mood.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${currentEntry.mood.label} • ${_dateFormat.format(currentEntry.date)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              const ThemeSelectorAction(),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddEntryScreen(entry: currentEntry),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete entry?'),
                      content: const Text(
                        'This memory will be removed from your diary. This action cannot be undone.',
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
                    ),
                  );

                  if (shouldDelete == true) {
                    await repository.deleteEntry(currentEntry.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientStart,
                  gradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: contentBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: isDark ? 24 : 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isNotebook
                          ? NotebookViewer(
                              key: const ValueKey('notebook-viewer'),
                              spreads: currentEntry.notebookSpreads,
                              appearance: currentEntry.notebookAppearance,
                            )
                          : (() {
                              final title = currentEntry.diaryTitle;
                              final body = currentEntry.diaryBody;
                              final text = title.isNotEmpty && body.isNotEmpty
                                  ? '$title\n\n$body'
                                  : title.isNotEmpty
                                      ? title
                                      : body;
                              return Text(
                                text,
                                key: const ValueKey('text-entry'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.5,
                                ),
                              );
                            })(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (currentEntry.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: currentEntry.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Center(
                    child: Text(
                      '✨ Keep shining. Your diary loves hearing from you.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
