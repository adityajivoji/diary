import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/diary_repository.dart';
import 'models/diary_entry.dart';
import 'screens/home_screen.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(DiaryEntryAdapter().typeId)) {
    Hive.registerAdapter(DiaryEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(NotebookAttachmentAdapter().typeId)) {
    Hive.registerAdapter(NotebookAttachmentAdapter());
  }
  if (!Hive.isAdapterRegistered(NotebookSpreadAdapter().typeId)) {
    Hive.registerAdapter(NotebookSpreadAdapter());
  }
  if (!Hive.isAdapterRegistered(NotebookAppearanceAdapter().typeId)) {
    Hive.registerAdapter(NotebookAppearanceAdapter());
  }
  await Hive.openBox<DiaryEntry>(DiaryRepository.boxName);

  final themeController = await ThemeController.load();

  runApp(PastelDiaryApp(themeController: themeController));
}

class PastelDiaryApp extends StatelessWidget {
  const PastelDiaryApp({required this.themeController, super.key});

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
