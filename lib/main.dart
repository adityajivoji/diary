import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/diary_repository.dart';
import 'models/diary_entry.dart';
import 'screens/home_screen.dart';
import 'services/storage_path_manager.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storagePathManager = StoragePathManager();
  runApp(AppRoot(storagePathManager: storagePathManager));
}

class AppRoot extends StatefulWidget {
  const AppRoot({required this.storagePathManager, super.key});

  final StoragePathManager storagePathManager;

  @override
  State<AppRoot> createState() => _AppRootState();
}

enum _AppInitState { loading, needsDirectory, ready }

class _AppRootState extends State<AppRoot> {
  _AppInitState _state = _AppInitState.loading;
  ThemeController? _themeController;
  String? _error;
  bool _isPickingDirectory = false;
  bool _hiveInitialized = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!Platform.isMacOS) {
      await _initializeHive();
      return;
    }

    final savedPath = await widget.storagePathManager.loadSavedPath();
    if (savedPath != null) {
      await _initializeHive(macPath: savedPath);
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _state = _AppInitState.needsDirectory;
    });
  }

  Future<void> _initializeHive({String? macPath}) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _state = _AppInitState.loading;
      _error = null;
    });

    try {
      if (!_hiveInitialized) {
        if (Platform.isMacOS) {
          if (macPath == null || macPath.isEmpty) {
            throw StateError('A storage directory is required on macOS.');
          }
          Hive.init(macPath);
        } else {
          await Hive.initFlutter();
        }

        _registerAdapters();

        if (!Hive.isBoxOpen(DiaryRepository.boxName)) {
          await Hive.openBox<DiaryEntry>(DiaryRepository.boxName);
        }

        _hiveInitialized = true;
      }

      final themeController = await ThemeController.load();

      if (!mounted) {
        return;
      }
      setState(() {
        _themeController = themeController;
        _state = _AppInitState.ready;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _state =
            Platform.isMacOS ? _AppInitState.needsDirectory : _AppInitState.loading;
      });
    }
  }

  void _registerAdapters() {
    final diaryEntryAdapter = DiaryEntryAdapter();
    if (!Hive.isAdapterRegistered(diaryEntryAdapter.typeId)) {
      Hive.registerAdapter(diaryEntryAdapter);
    }

    final notebookAttachmentAdapter = NotebookAttachmentAdapter();
    if (!Hive.isAdapterRegistered(notebookAttachmentAdapter.typeId)) {
      Hive.registerAdapter(notebookAttachmentAdapter);
    }

    final notebookSpreadAdapter = NotebookSpreadAdapter();
    if (!Hive.isAdapterRegistered(notebookSpreadAdapter.typeId)) {
      Hive.registerAdapter(notebookSpreadAdapter);
    }

    final notebookAppearanceAdapter = NotebookAppearanceAdapter();
    if (!Hive.isAdapterRegistered(notebookAppearanceAdapter.typeId)) {
      Hive.registerAdapter(notebookAppearanceAdapter);
    }
  }

  Future<void> _handleChooseDirectory() async {
    if (_isPickingDirectory) {
      return;
    }

    setState(() {
      _isPickingDirectory = true;
      _error = null;
    });

    try {
      final selectedPath =
          await widget.storagePathManager.promptUserForDirectory();
      if (selectedPath == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = 'Please choose a folder to continue.';
        });
        return;
      }

      await _initializeHive(macPath: selectedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not use the selected folder. ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingDirectory = false;
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(widget.storagePathManager.releaseActiveBookmark());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AppInitState.loading:
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      case _AppInitState.needsDirectory:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MacStorageSetupScreen(
            onChoosePressed: _handleChooseDirectory,
            busy: _isPickingDirectory,
            error: _error,
          ),
        );
      case _AppInitState.ready:
        return SharuDiaryApp(themeController: _themeController!);
    }
  }
}

class MacStorageSetupScreen extends StatelessWidget {
  const MacStorageSetupScreen({
    required this.onChoosePressed,
    this.busy = false,
    this.error,
    super.key,
  });

  final Future<void> Function() onChoosePressed;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_open,
                  color: Theme.of(context).colorScheme.primary,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose where to store your diary',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sharu, Pick a folder for your Diary entries so they stay safe even if you reinstall the app.',
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: busy ? null : onChoosePressed,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Choose Folder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SharuDiaryApp extends StatelessWidget {
  const SharuDiaryApp({required this.themeController, super.key});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return ThemeControllerProvider(
          controller: themeController,
          child: MaterialApp(
            title: 'Pastel Diary',
            debugShowCheckedModeBanner: false,
            theme: themeController.themeData,
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
