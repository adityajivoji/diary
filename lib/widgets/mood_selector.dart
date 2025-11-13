import 'package:flutter/material.dart';

import '../models/mood.dart';

typedef MoodChangedCallback = void Function(Mood? mood);

/// Presents the available moods as cute emoji chips.
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    required this.moods,
    required this.selectedMood,
    required this.onMoodSelected,
    this.allowClear = false,
    this.onAddMood,
    super.key,
  });

  final List<Mood> moods;
  final Mood? selectedMood;
  final MoodChangedCallback onMoodSelected;
  final bool allowClear;
  final VoidCallback? onAddMood;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mood in moods)
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
        if (onAddMood != null)
          Tooltip(
            message: 'Feeling something else?',
            child: ActionChip(
              label: const Text('Add mood'),
              avatar: const Icon(Icons.add, size: 18),
              onPressed: onAddMood,
              backgroundColor: Theme.of(context).chipTheme.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        if (allowClear && selectedMood != null)
          ActionChip(
            label: const Text('Clear'),
            avatar: const Icon(Icons.refresh, size: 18),
            onPressed: () => onMoodSelected(null),
            backgroundColor: Theme.of(context).chipTheme.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
      ],
    );
  }
}
