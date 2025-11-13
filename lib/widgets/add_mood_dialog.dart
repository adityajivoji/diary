import 'package:flutter/material.dart';

import '../data/mood_repository.dart';
import '../models/mood.dart';

/// Dialog that lets the user create a new custom mood.
class AddMoodDialog extends StatefulWidget {
  const AddMoodDialog({this.initialMood, super.key});

  final Mood? initialMood;

  @override
  State<AddMoodDialog> createState() => _AddMoodDialogState();
}

class _AddMoodDialogState extends State<AddMoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emojiController = TextEditingController();
  final _labelController = TextEditingController();
  final MoodRepository _repository = MoodRepository.instance;

  bool _isSubmitting = false;
  String? _errorText;

  bool get _isEditing => widget.initialMood != null;

  @override
  void dispose() {
    _emojiController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final mood = widget.initialMood;
    if (mood != null) {
      _emojiController.text = mood.emoji;
      _labelController.text = mood.label;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final emoji = _emojiController.text.trim();
    final label = _labelController.text.trim();

    final existingId = widget.initialMood?.id;
    if (_repository.labelExists(label, excludeId: existingId)) {
      setState(() {
        _errorText =
            'You already have a mood with that name. Try something else!';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final mood = _isEditing
          ? await _repository.updateCustomMood(
              id: existingId!,
              emoji: emoji,
              label: label,
            )
          : await _repository.createCustomMood(
              emoji: emoji,
              label: label,
            );
      if (!mounted) return;
      Navigator.of(context).pop<Mood>(mood);
    } catch (error) {
      setState(() {
        _errorText =
            'Could not ${_isEditing ? 'update' : 'save'} your mood. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dialogTitle = _isEditing ? 'Edit mood' : 'Add a new mood';
    final submitLabel = _isEditing ? 'Update' : 'Save';

    return AlertDialog(
      title: Text(dialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emojiController,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: 'Pick an emoji that matches your vibe',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Add at least one emoji';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labelController,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Mood label',
                hintText: 'Give your mood a short name',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Give your mood a name';
                }
                if (value.trim().length < 2) {
                  return 'Use at least two letters';
                }
                return null;
              },
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          icon: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(submitLabel),
        ),
      ],
    );
  }
}
