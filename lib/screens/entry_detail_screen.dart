import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';
import 'add_entry_screen.dart';

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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your memory'),
            actions: [
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  Center(
                    child: Text(
                      currentEntry.mood.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      currentEntry.mood.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _dateFormat.format(currentEntry.date),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
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
                    child: Text(
                      currentEntry.content,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
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
