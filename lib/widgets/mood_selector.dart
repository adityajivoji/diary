import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../theme/app_colors.dart';

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
            onSelected: (_) => onMoodSelected(mood),
            selectedColor: AppColors.mintMist.withOpacity(0.8),
          ),
        if (allowClear && selectedMood != null)
          ActionChip(
            label: const Text('Clear'),
            avatar: const Icon(Icons.refresh, size: 18),
            onPressed: () => onMoodSelected(null),
            backgroundColor: Colors.white.withOpacity(0.85),
          ),
      ],
    );
  }
}
