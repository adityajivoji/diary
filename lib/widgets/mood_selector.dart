import 'package:flutter/material.dart';

import '../models/diary_entry.dart';

typedef MoodChangedCallback = void Function(Mood? mood);

/// Presents the available moods as cute emoji chips.
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    required this.selectedMood,
    required this.onMoodSelected,
    this.allowClear = false,
    super.key,
  });

  final Mood? selectedMood;
  final MoodChangedCallback onMoodSelected;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mood in Mood.values)
          ChoiceChip(
            label: Text('${mood.emoji} ${mood.label}'),
            selected: selectedMood == mood,
            onSelected: (_) {
              if (allowClear && selectedMood == mood) {
                onMoodSelected(null);
              } else {
                onMoodSelected(mood);
              }
            },
            selectedColor: Theme.of(context).chipTheme.selectedColor,
          ),
        if (allowClear && selectedMood != null)
          ActionChip(
            label: const Text('Clear'),
            avatar: const Icon(Icons.refresh, size: 18),
            onPressed: () => onMoodSelected(null),
            backgroundColor:
                Theme.of(context).chipTheme.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
      ],
    );
  }
}
