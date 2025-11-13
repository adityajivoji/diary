import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data/diary_repository.dart';
import '../data/mood_repository.dart';
import '../models/diary_entry.dart';
import '../models/custom_mood.dart';
import '../widgets/entry_card.dart';
import '../widgets/mood_selector.dart';
import '../widgets/theme_selector_action.dart';
import '../widgets/add_mood_dialog.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';

enum MoodFilterMode {
  any,
  all,
}

/// Home screen that displays existing entries and quick filters.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DiaryRepository _repository = DiaryRepository.instance;
  final MoodRepository _moodRepository = MoodRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFilterFormat = DateFormat.yMMMMd();

  List<Mood> _selectedMoods = const <Mood>[];
  MoodFilterMode _moodFilterMode = MoodFilterMode.any;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearch)
      ..dispose();
    super.dispose();
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _selectedDateRange ?? DateTimeRange(start: now, end: now);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearDateRange() {
    setState(() => _selectedDateRange = null);
  }

  void _toggleSortOrder() {
    setState(() => _sortDescending = !_sortDescending);
  }

  void _openAddEntry() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const AddEntryScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _handleAddMood() async {
    final newMood = await showDialog<Mood>(
      context: context,
      builder: (context) => const AddMoodDialog(),
    );
    if (newMood != null && mounted) {
      if (_selectedMoods.any((mood) => mood.id == newMood.id)) {
        return;
      }
      setState(() {
        final updated = List<Mood>.from(_selectedMoods)..add(newMood);
        _selectedMoods = List.unmodifiable(updated);
      });
    }
  }

  Future<void> _handleDeleteMood(Mood mood) async {
    if (!mood.isCustom) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete mood'),
          content: Text(
            'Are you sure you want to delete "${mood.label}"? '
            'Existing entries will keep their saved emoji and label.',
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
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await _moodRepository.deleteCustomMood(mood.id);
      if (!mounted) return;
      if (_selectedMoods.any((selected) => selected.id == mood.id)) {
        setState(() {
          _selectedMoods = List.unmodifiable(
            _selectedMoods.where((selected) => selected.id != mood.id),
          );
          if (_selectedMoods.isEmpty) {
            _moodFilterMode = MoodFilterMode.any;
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${mood.label}".')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete that mood. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleEditMood(Mood mood) async {
    if (!mood.isCustom) {
      return;
    }
    final updatedMood = await showDialog<Mood>(
      context: context,
      builder: (context) => AddMoodDialog(initialMood: mood),
    );
    if (!mounted || updatedMood == null) {
      return;
    }
    if (_selectedMoods.any((selected) => selected.id == updatedMood.id)) {
      setState(() {
        _selectedMoods = List.unmodifiable(
          _selectedMoods
              .map(
                (selected) =>
                    selected.id == updatedMood.id ? updatedMood : selected,
              )
              .toList(),
        );
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated "${updatedMood.label}".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);
    final filterBackground = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.78)
        : Colors.transparent;
    final filterButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: filterBackground,
      foregroundColor: theme.colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pastel Diary'),
        actions: const [
          ThemeSelectorAction(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search your memories...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mood filter',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<Box<CustomMood>>(
                    valueListenable: _moodRepository.listenable(),
                    builder: (context, _, __) {
                      final moods = _moodRepository.getAllMoods();
                      final selected = _selectedMoods;
                      final moodById = {
                        for (final mood in moods) mood.id: mood
                      };
                      if (selected.isNotEmpty) {
                        final updatedSelection = <Mood>[];
                        var selectionChanged = false;
                        for (final mood in selected) {
                          final replacement = moodById[mood.id];
                          if (replacement == null) {
                            selectionChanged = true;
                            continue;
                          }
                          if (!identical(replacement, mood)) {
                            selectionChanged = true;
                          }
                          updatedSelection.add(replacement);
                        }
                        if (selectionChanged) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _selectedMoods =
                                  List.unmodifiable(updatedSelection);
                              if (_selectedMoods.isEmpty) {
                                _moodFilterMode = MoodFilterMode.any;
                              }
                            });
                          });
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MoodSelector(
                            moods: moods,
                            selectedMoods: _selectedMoods,
                            multiSelect: true,
                            allowClear: true,
                            onSelectedMoodsChanged: (moods) {
                              setState(() {
                                _selectedMoods = List.unmodifiable(moods);
                                if (_selectedMoods.isEmpty) {
                                  _moodFilterMode = MoodFilterMode.any;
                                }
                              });
                            },
                            onAddMood: _handleAddMood,
                            onDeleteMood: _handleDeleteMood,
                            onEditMood: _handleEditMood,
                          ),
                          if (_selectedMoods.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildMoodFilterModeToggle(theme, labelColor),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Date & sort',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_selectedDateRange != null) {
                              _clearDateRange();
                            } else {
                              _pickDateRange();
                            }
                          },
                          style: filterButtonStyle,
                          icon: const Icon(Icons.event_rounded),
                          label: Text(
                            _selectedDateRange == null
                                ? 'Filter by date'
                                : _formatDateRange(_selectedDateRange!),
                          ),
                        ),
                      ),
                      if (_selectedDateRange != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: IconButton(
                            tooltip: 'Clear date filter',
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: _clearDateRange,
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleSortOrder,
                          style: filterButtonStyle,
                          icon: Icon(
                            _sortDescending
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                          ),
                          label: Text(_sortDescending
                              ? 'Newest first'
                              : 'Oldest first'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Box<DiaryEntry>>(
                valueListenable: _repository.listenable(),
                builder: (context, _, __) {
                  final entries = _repository.getAllEntries();
                  final filteredEntries = entries.where((entry) {
                    final matchesMood = _selectedMoods.isEmpty ||
                        (_moodFilterMode == MoodFilterMode.all
                            ? _selectedMoods
                                .every((mood) => entry.moods.contains(mood))
                            : _selectedMoods
                                .any((mood) => entry.moods.contains(mood)));
                    final matchesQuery = _matchesSearchQuery(entry);
                    final matchesDate = _selectedDateRange == null ||
                        _isWithinRange(entry.date, _selectedDateRange!);
                    return matchesMood && matchesQuery && matchesDate;
                  }).toList();

                  filteredEntries.sort(
                    (a, b) => _sortDescending
                        ? b.date.compareTo(a.date)
                        : a.date.compareTo(b.date),
                  );

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: filteredEntries.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96, top: 8),
                            itemCount: filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = filteredEntries[index];
                              return EntryCard(
                                entry: entry,
                                onTap: () => _openEntryDetail(entry),
                                onDelete: () =>
                                    _repository.deleteEntry(entry.id),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodFilterModeToggle(ThemeData theme, Color labelColor) {
    final description = _moodFilterMode == MoodFilterMode.all
        ? 'Show entries that match all selected moods'
        : 'Show entries that match any selected mood';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        ToggleButtons(
          borderRadius: BorderRadius.circular(20),
          isSelected: [
            _moodFilterMode == MoodFilterMode.any,
            _moodFilterMode == MoodFilterMode.all,
          ],
          onPressed: (index) {
            setState(() {
              _moodFilterMode =
                  index == 0 ? MoodFilterMode.any : MoodFilterMode.all;
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('OR'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('AND'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.cardColor,
            border: Border.all(
              color: onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Text(
                'No entries yet!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap the cupcake to tell your story for today. '
                'Add how you feel, then come back later to read your memories.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurface.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openAddEntry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                ),
                icon: const Text('🧁', style: TextStyle(fontSize: 20)),
                label: const Text('Add your first entry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEntryDetail(DiaryEntry entry) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => EntryDetailScreen(entry: entry),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isWithinRange(DateTime date, DateTimeRange range) {
    final start =
        DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final candidate = DateTime(date.year, date.month, date.day);

    final afterStart = candidate.isAfter(start) || _isSameDay(candidate, start);
    final beforeEnd = candidate.isBefore(end) || _isSameDay(candidate, end);
    return afterStart && beforeEnd;
  }

  String _formatDateRange(DateTimeRange range) {
    if (_isSameDay(range.start, range.end)) {
      return _dateFilterFormat.format(range.start);
    }

    final startText = _dateFilterFormat.format(range.start);
    final endText = _dateFilterFormat.format(range.end);
    return '$startText - $endText';
  }

  bool _matchesSearchQuery(DiaryEntry entry) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    final query = _searchQuery;
    final parts = _collectSearchParts(entry);

    if (parts.isEmpty) {
      return false;
    }

    if (query.length >= 2 && parts.any((part) => part.contains(query))) {
      return true;
    }

    final tokens = query
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty && token.length > 1)
        .toList();

    if (tokens.isEmpty) {
      return parts.any((part) => _tokenMatchesPart(query, part));
    }

    for (final token in tokens) {
      final matchesToken = parts.any((part) => _tokenMatchesPart(token, part));
      if (!matchesToken) {
        return false;
      }
    }
    return true;
  }

  List<String> _collectSearchParts(DiaryEntry entry) {
    final parts = <String>[];

    if (entry.usesNotebook) {
      if (entry.notebookSummary.trim().isNotEmpty) {
        final normalized = _normalizePart(entry.notebookSummary);
        if (normalized != null) {
          parts.add(normalized);
        }
      }
      for (final spread in entry.notebookSpreads) {
        if (spread.text.trim().isNotEmpty) {
          final normalized = _normalizePart(spread.text);
          if (normalized != null) {
            parts.add(normalized);
          }
        }
      }
    } else {
      final title = entry.diaryTitle.trim();
      final body = entry.diaryBody.trim();
      final normalizedTitle = _normalizePart(title);
      final normalizedBody = _normalizePart(body);
      if (normalizedTitle != null) parts.add(normalizedTitle);
      if (normalizedBody != null) parts.add(normalizedBody);
    }

    for (final tag in entry.tags) {
      final trimmed = tag.trim();
      if (trimmed.isNotEmpty) {
        final normalized = _normalizePart(trimmed);
        if (normalized != null) {
          parts.add(normalized);
        }
      }
    }

    if (parts.isEmpty && entry.content.trim().isNotEmpty) {
      final normalized = _normalizePart(entry.content);
      if (normalized != null) {
        parts.add(normalized);
      }
    }

    return parts;
  }

  bool _tokenMatchesPart(String token, String part) {
    if (part.contains(token)) {
      return true;
    }

    if (token.length <= 2) {
      return false;
    }

    final words = part
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();

    final threshold = _similarityThreshold(token.length);

    for (final word in words) {
      final similarity = _similarity(word, token);
      if (similarity >= threshold) {
        return true;
      }
    }

    if (token.contains(' ') && part.length > token.length) {
      final similarity = _similarity(part, token);
      if (similarity >= threshold) {
        return true;
      }
    }

    return false;
  }

  double _similarityThreshold(int tokenLength) {
    if (tokenLength >= 8) return 0.6;
    if (tokenLength >= 5) return 0.7;
    return 0.8;
  }

  double _similarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final distance = _levenshtein(a, b);
    final maxLength = math.max(a.length, b.length);
    if (maxLength == 0) return 1;
    return 1 - distance / maxLength;
  }

  String? _normalizePart(String text, {int maxLength = 500}) {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return trimmed.substring(0, maxLength);
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;

    var previousRow = List<int>.generate(n + 1, (index) => index);
    var currentRow = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      currentRow[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        currentRow[j] = math.min(
          math.min(currentRow[j - 1] + 1, previousRow[j] + 1),
          previousRow[j - 1] + cost,
        );
      }
      previousRow = currentRow;
      currentRow = List<int>.filled(n + 1, 0);
    }

    return previousRow[n];
  }
}
