# Pastel Diary

Pastel Diary is a cute, minimal Flutter journal app designed with soft pastel colors, an adorable mood picker, and smooth animations. It works entirely offline thanks to Hive for local persistence.
# defaults delete com.example.pastelDiary
## Project Structure

```
lib/
 ├─ data/
 │   └─ diary_repository.dart
 ├─ models/
 │   └─ diary_entry.dart
 ├─ screens/
 │   ├─ add_entry_screen.dart
 │   ├─ entry_detail_screen.dart
 │   └─ home_screen.dart
 ├─ theme/
 │   ├─ app_colors.dart
 │   └─ app_theme.dart
 ├─ widgets/
 │   ├─ entry_card.dart
 │   └─ mood_selector.dart
 └─ main.dart
```

## Getting Started

1. **Install Flutter**  
   Follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install) for your platform.

2. **Fetch dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Build an Android APK

Make sure you have an Android device or emulator configured:

```bash
flutter build apk --release
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`. You can transfer it to an Android device and install it after enabling installs from unknown sources.

## Features

- 🧁 Floating _Add Entry_ button
- 📜 Past entries list with pastel cards
- 🔍 Filter entries by mood and search text
- 💫 Soft fade animations and rounded corners
- 😊 Mood selector with emoji chips
- 💾 Offline storage via Hive

## Notes

- The Hive box is opened in `main.dart` and ready before the UI renders.
- Entries are sorted by date (newest first) and stored with a unique `id`.
- Mood filtering is optional; clearing the mood filter shows every entry.
