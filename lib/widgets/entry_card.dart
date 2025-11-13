import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';

/// Small card preview for a diary entry in the list.
class EntryCard extends StatelessWidget {
  EntryCard({
    required this.entry,
    required this.onTap,
    this.onDelete,
    super.key,
  }) : _dateFormat = DateFormat('EEE, MMM d');

  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  final DateFormat _dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        theme.colorScheme.secondaryContainer.withValues(alpha: 0.6);
    final notebookAccent = theme.colorScheme.secondary;
    final summary = entry.usesNotebook
        ? entry.notebookSummary
        : (() {
            final title = entry.diaryTitle;
            final body = entry.diaryBody;
            if (title.isNotEmpty && body.isNotEmpty) {
              return '$title\n$body';
            }
            if (title.isNotEmpty) return title;
            return body;
          })();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: onDelete == null
            ? DismissDirection.none
            : DismissDirection.endToStart,
        onDismissed: (_) => onDelete?.call(),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        entry.mood.emoji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, height: 1.1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateFormat.format(entry.date),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entry.usesNotebook) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: notebookAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Notebook entry',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: notebookAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ] else
                          const SizedBox(height: 4),
                        Text(
                          summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (entry.hasMultipleMoods) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: entry.moods
                                .map(
                                  (mood) => Chip(
                                    label: Text('${mood.emoji} ${mood.label}'),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (entry.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: entry.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
