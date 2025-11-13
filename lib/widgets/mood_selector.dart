import 'package:flutter/material.dart';

import '../models/mood.dart';

typedef MoodChangedCallback = void Function(Mood? mood);
typedef MoodsChangedCallback = void Function(List<Mood> moods);
typedef MoodDeleteCallback = void Function(Mood mood);
typedef MoodEditCallback = void Function(Mood mood);

/// Presents the available moods as cute emoji chips.
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    required this.moods,
    this.selectedMood,
    this.selectedMoods = const <Mood>[],
    this.onMoodSelected,
    this.onSelectedMoodsChanged,
    this.multiSelect = false,
    this.allowClear = false,
    this.onAddMood,
    this.onDeleteMood,
    this.onEditMood,
    super.key,
  }) : assert(
          multiSelect ? onSelectedMoodsChanged != null : onMoodSelected != null,
          'Provide a callback matching the selection mode.',
        );

  final List<Mood> moods;
  final Mood? selectedMood;
  final List<Mood> selectedMoods;
  final MoodChangedCallback? onMoodSelected;
  final MoodsChangedCallback? onSelectedMoodsChanged;
  final bool multiSelect;
  final bool allowClear;
  final VoidCallback? onAddMood;
  final MoodDeleteCallback? onDeleteMood;
  final MoodEditCallback? onEditMood;

  bool _isSelected(Mood mood) {
    if (multiSelect) {
      return selectedMoods.any((selected) => selected == mood);
    }
    return selectedMood == mood;
  }

  void _handleSelection(Mood mood) {
    if (multiSelect) {
      final current = List<Mood>.from(selectedMoods);
      final index = current.indexWhere((selected) => selected == mood);
      if (index >= 0) {
        current.removeAt(index);
      } else {
        current.add(mood);
      }
      onSelectedMoodsChanged?.call(current);
      return;
    }

    final isSelected = selectedMood == mood;
    if (allowClear && isSelected) {
      onMoodSelected?.call(null);
    } else {
      onMoodSelected?.call(mood);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;
    final defaultBackground =
        chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final selectedColor =
        chipTheme.selectedColor ?? theme.colorScheme.secondaryContainer;
    final checkmarkColor = chipTheme.secondaryLabelStyle?.color ??
        theme.colorScheme.onSecondaryContainer;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mood in moods)
          _buildMoodChip(
            context,
            mood: mood,
            selectedColor: selectedColor,
            defaultBackground: defaultBackground,
            checkmarkColor: checkmarkColor,
          ),
        if (onAddMood != null)
          Tooltip(
            message: 'Feeling something else?',
            child: ActionChip(
              label: const Text('Add mood'),
              avatar: const Icon(Icons.add, size: 18),
              onPressed: onAddMood,
              backgroundColor: chipTheme.backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        if (!multiSelect && allowClear && selectedMood != null)
          ActionChip(
            label: const Text('Clear'),
            avatar: const Icon(Icons.refresh, size: 18),
            onPressed: () => onMoodSelected?.call(null),
            backgroundColor: chipTheme.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        if (multiSelect && allowClear && selectedMoods.isNotEmpty)
          ActionChip(
            label: const Text('Clear'),
            avatar: const Icon(Icons.refresh, size: 18),
            onPressed: () => onSelectedMoodsChanged?.call(const <Mood>[]),
            backgroundColor: chipTheme.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
      ],
    );
  }

  Widget _buildMoodChip(
    BuildContext context, {
    required Mood mood,
    required Color? selectedColor,
    required Color defaultBackground,
    required Color checkmarkColor,
  }) {
    final chip = InputChip(
      label: Text('${mood.emoji} ${mood.label}'),
      selected: _isSelected(mood),
      onPressed: () => _handleSelection(mood),
      selectedColor: selectedColor,
      backgroundColor: defaultBackground,
      showCheckmark: multiSelect,
      checkmarkColor: multiSelect ? checkmarkColor : null,
      onDeleted: mood.isCustom && onDeleteMood != null
          ? () => onDeleteMood!(mood)
          : null,
      deleteIcon: mood.isCustom && onDeleteMood != null
          ? const Icon(Icons.delete_outline)
          : null,
      deleteIconColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      deleteButtonTooltipMessage: mood.isCustom && onDeleteMood != null
          ? 'Delete "${mood.label}"'
          : null,
    );

    if (mood.isCustom && onEditMood != null) {
      return Tooltip(
        message: 'Tap to select.\nLong press to edit.',
        child: GestureDetector(
          onLongPress: () => onEditMood!(mood),
          child: chip,
        ),
      );
    }
    return chip;
  }
}
