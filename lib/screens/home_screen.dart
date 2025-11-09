import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';
import '../theme/theme_controller.dart';
import '../widgets/entry_card.dart';
import '../widgets/mood_selector.dart';
import '../widgets/theme_selector_sheet.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';

/// Home screen that displays existing entries and quick filters.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DiaryRepository _repository = DiaryRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFilterFormat = DateFormat.yMMMMd();

  Mood? _selectedMood;
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

  void _openThemeSelector() {
    final controller = ThemeControllerProvider.of(context);
    final dialogTheme = Theme.of(context).dialogTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: dialogTheme.backgroundColor,
      shape: dialogTheme.shape,
      builder: (_) => ThemeSelectorSheet(controller: controller),
    );
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
        actions: [
          IconButton(
            tooltip: 'Choose theme',
            icon: const Icon(Icons.palette_rounded),
            onPressed: _openThemeSelector,
          ),
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
                  MoodSelector(
                    selectedMood: _selectedMood,
                    onMoodSelected: (mood) =>
                        setState(() => _selectedMood = mood),
                    allowClear: true,
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
                    final matchesMood =
                        _selectedMood == null || entry.mood == _selectedMood;
                    final matchesQuery = _searchQuery.isEmpty ||
                        entry.content.toLowerCase().contains(_searchQuery);
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

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.9),
          ),
          child: Column(
            children: [
              const Text(
                'No entries yet!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap the cupcake to tell your story for today. '
                'Add how you feel, then come back later to read your memories.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openAddEntry,
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
}
