#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME=${1:-pomopet}
OUT_DIR=${2:-$PWD/_app}
BLUEPRINT_DIR=${3:-$PWD/pomopet_blueprint}

# Resolve to absolute paths early, before changing directory.
OUT_DIR=$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$OUT_DIR")
BLUEPRINT_DIR=$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$BLUEPRINT_DIR")

rm -rf "$OUT_DIR"
mkdir -p "$(dirname "$OUT_DIR")"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Create Flutter project in a temp dir, then move into OUT_DIR.
flutter create "$TMP_DIR/$PROJECT_NAME"
mv "$TMP_DIR/$PROJECT_NAME" "$OUT_DIR"

cd "$OUT_DIR"
mkdir -p assets/config

echo "[pomopet] blueprint dir: $BLUEPRINT_DIR"
ls -la "$BLUEPRINT_DIR" || true

# Inject blueprint
cp -r "$BLUEPRINT_DIR/lib"/* lib/
cp -r "$BLUEPRINT_DIR/assets/config"/* assets/config/

# Use skeleton main
if [ -f lib/main_skeleton.dart ]; then
  cp lib/main_skeleton.dart lib/main.dart
fi

# Remove default sample test that references MyApp.
rm -f test/widget_test.dart

echo "[pomopet] rewrite pubspec.yaml"
cat > pubspec.yaml <<YAML
name: ${PROJECT_NAME}
description: Pomopet runnable project generated in CI
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  drift: ^2.18.0
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.0
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
  path_provider: ^2.1.0
  path: ^1.9.0
  crypto: ^3.0.3
  image_picker: ^1.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.9

flutter:
  uses-material-design: true
  assets:
    - assets/config/manifest.json
    - assets/config/strings_zh.json
    - assets/config/events.json
    - assets/config/game_config.json
    - assets/config/timer_presets.json
YAML

# Patch Android build for flutter_local_notifications (core library desugaring).
if [ -f android/app/build.gradle.kts ]; then
python3 - <<'PY'
from pathlib import Path
import re

p = Path('android/app/build.gradle.kts')
text = p.read_text(encoding='utf-8')

if 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:' not in text:
    if re.search(r'dependencies\s*\{', text):
        text = re.sub(
            r'dependencies\s*\{',
            'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")',
            text,
            count=1,
        )
    else:
        text += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n'

if 'isCoreLibraryDesugaringEnabled = true' not in text and 'coreLibraryDesugaringEnabled = true' not in text:
    m = re.search(r'compileOptions\s*\{', text)
    if m:
        insert_at = m.end()
        text = text[:insert_at] + '\n        isCoreLibraryDesugaringEnabled = true' + text[insert_at:]

p.write_text(text, encoding='utf-8')
print(text)
PY
fi

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
