// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:sharu_diary/data/diary_repository.dart';
import 'package:sharu_diary/main.dart';
import 'package:sharu_diary/models/diary_entry.dart';
import 'package:sharu_diary/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sharu_diary_test');
    Hive.init(tempDir.path);
    final adapter = DiaryEntryAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
    await Hive.openBox<DiaryEntry>(DiaryRepository.boxName);
    await Hive.openBox('settings_box');
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Home screen shows empty state when no entries', (WidgetTester tester) async {
    final themeController = await ThemeController.load();

    await tester.pumpWidget(SharuDiaryApp(themeController: themeController));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No entries yet!'), findsOneWidget);
    expect(find.text('Add your first entry'), findsOneWidget);

    themeController.dispose();
  });
}
