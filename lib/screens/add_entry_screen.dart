import 'package:flutter/material.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';
import '../widgets/mood_selector.dart';

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
  Mood? _selectedMood;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _contentController = TextEditingController(text: entry?.content ?? '');
    _selectedDate = entry?.date ?? DateTime.now();
    _selectedMood = entry?.mood ?? Mood.happy;
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

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final content = _contentController.text.trim();
    final mood = _selectedMood ?? Mood.happy;

    final entry = (_isEditing ? widget.entry! : null)?.copyWith(
          date: _selectedDate,
          mood: mood,
          content: content,
        ) ??
        DiaryEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: _selectedDate,
          mood: mood,
          content: content,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Update entry' : 'New entry'),
        actions: [
          IconButton(
            onPressed: _saveEntry,
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save entry',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your day?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Mood: ${(_selectedMood ?? Mood.happy).emoji}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  onMoodSelected: (mood) => setState(() => _selectedMood = mood ?? Mood.happy),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _contentController,
                  minLines: 8,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Dear diary...',
                  ),
                  validator: (value) {
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
                  label: Text(_isEditing ? 'Update entry' : 'Save entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
