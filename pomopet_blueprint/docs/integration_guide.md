# Pomopet blueprint integration guide

This blueprint is a *copy-paste kit* (not a full Flutter project). Follow these steps to integrate into a real Flutter app.

## 1) Create a Flutter app
```bash
flutter create pomopet
cd pomopet
```

## 2) Copy files
Copy the blueprint contents into your Flutter project:
- `projects/pomopet_blueprint/lib/*` -> `lib/`
- `projects/pomopet_blueprint/assets/config/*` -> `assets/config/`

## 3) pubspec.yaml
Add dependencies (versions are indicative):

```yaml
dependencies:
  flutter:
    sdk: flutter

  drift: ^2.18.0
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.0

  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4

  path_provider: ^2.1.0
  path: ^1.9.0
  crypto: ^3.0.3

dev_dependencies:
  drift_dev: ^2.18.0
  build_runner: ^2.4.9
```

Register assets:

```yaml
flutter:
  assets:
    - assets/config/manifest.json
    - assets/config/strings_zh.json
    - assets/config/events.json
    - assets/config/game_config.json
    - assets/config/timer_presets.json
```

Then:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## 4) Replace main.dart
Use the provided skeleton as reference:
- `lib/main_skeleton.dart`

Minimal snippet:
```dart
void main() async {
  final runtime = await bootstrapPomopet();
  runApp(MaterialApp(
    navigatorKey: pomopetNavKey,
    theme: PomopetTheme.light(),
    home: /* TimerPage(...) */,
  ));
}
```

## 5) Android notes
- Android 13+: you must request notification permission at runtime.
- For best timer reliability, use a Foreground Service plugin (see `docs/android_foreground_service.md`).

## 6) iOS notes
- Request notification permission when the user first starts a timer.
- iOS will not keep a long-running background timer reliably; use scheduled finish notifications + `endAt` reconciliation.

## 7) MVP test checklist
- Start focus
- Pause/resume
- Finish notification fires
- Tap finish notification -> completion sheet shows
- Confirm -> completion_logs inserted; user xp/coin updated; level-up dialog shows on level increase
- dayCutoff affects logical date as expected
