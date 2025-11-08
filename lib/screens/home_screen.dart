import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/diary_repository.dart';
import '../models/diary_entry.dart';
import '../theme/app_colors.dart';
import '../widgets/entry_card.dart';
import '../widgets/mood_selector.dart';
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

  Mood? _selectedMood;
  String _searchQuery = '';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pastel Diary'),
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
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.deepMocha.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: 8),
                  MoodSelector(
                    selectedMood: _selectedMood,
                    onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                    allowClear: true,
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
                    final matchesMood = _selectedMood == null || entry.mood == _selectedMood;
                    final matchesQuery = _searchQuery.isEmpty ||
                        entry.content.toLowerCase().contains(_searchQuery);
                    return matchesMood && matchesQuery;
                  }).toList();

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
                                onDelete: () => _repository.deleteEntry(entry.id),
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
            color: Colors.white.withOpacity(0.9),
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
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }
}
