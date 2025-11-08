import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/diary_repository.dart';
import 'models/diary_entry.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(DiaryEntryAdapter().typeId)) {
    Hive.registerAdapter(DiaryEntryAdapter());
  }
  await Hive.openBox<DiaryEntry>(DiaryRepository.boxName);

  runApp(const PastelDiaryApp());
}

class PastelDiaryApp extends StatelessWidget {
  const PastelDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastel Diary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const HomeScreen(),
    );
  }
}
