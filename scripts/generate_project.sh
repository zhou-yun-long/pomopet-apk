#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME=${1:-pomopet}
OUT_DIR=${2:-$PWD/_app}
BLUEPRINT_DIR=${3:-$PWD/pomopet_blueprint}

rm -rf "$OUT_DIR"
mkdir -p "$(dirname "$OUT_DIR")"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Create Flutter project in a temp dir, then move into OUT_DIR.
flutter create "$TMP_DIR/$PROJECT_NAME"
mv "$TMP_DIR/$PROJECT_NAME" "$OUT_DIR"

cd "$OUT_DIR"
mkdir -p assets/config

# Inject blueprint
cp -r "$BLUEPRINT_DIR/lib"/* lib/
cp -r "$BLUEPRINT_DIR/assets/config"/* assets/config/

# Use skeleton main
if [ -f lib/main_skeleton.dart ]; then
  cp lib/main_skeleton.dart lib/main.dart
fi

echo "[pomopet] patch pubspec.yaml"
python3 - <<'PY'
from pathlib import Path

pub = Path('pubspec.yaml')
lines = pub.read_text(encoding='utf-8').splitlines(True)

def insert_block(key: str, block_lines: list[str]):
    # Find top-level key line like 'dependencies:'
    try:
        i = next(idx for idx,l in enumerate(lines) if l.strip() == f'{key}:')
    except StopIteration:
        return False
    # Find end of this section: next non-indented top-level key (col 0, endswith ':')
    j = i + 1
    while j < len(lines):
        l = lines[j]
        if l and not l.startswith(' ') and l.rstrip().endswith(':'):
            break
        j += 1
    # Insert before j
    # Ensure block lines end with '\n'
    ins = [bl if bl.endswith('\n') else bl+'\n' for bl in block_lines]
    lines[j:j] = ins
    return True

# Add dependencies (do not duplicate if already present)
need_deps = {
  'drift': '^2.18.0',
  'drift_flutter': '^0.1.0',
  'sqlite3_flutter_libs': '^0.5.0',
  'flutter_local_notifications': '^17.2.2',
  'timezone': '^0.9.4',
  'path_provider': '^2.1.0',
  'path': '^1.9.0',
  'crypto': '^3.0.3',
  'image_picker': '^1.1.2',
}
need_dev = {
  'drift_dev': '^2.18.0',
  'build_runner': '^2.4.9',
}

text = ''.join(lines)

dep_block = []
for k,v in need_deps.items():
    if f'  {k}:' not in text:
        dep_block.append(f'  {k}: {v}')

dev_block = []
for k,v in need_dev.items():
    if f'  {k}:' not in text:
        dev_block.append(f'  {k}: {v}')

if dep_block:
    insert_block('dependencies', dep_block)
if dev_block:
    insert_block('dev_dependencies', dev_block)

# Ensure assets listed under flutter:
assets = [
  '    - assets/config/manifest.json',
  '    - assets/config/strings_zh.json',
  '    - assets/config/events.json',
  '    - assets/config/game_config.json',
  '    - assets/config/timer_presets.json',
]

# Find flutter: section
try:
    fi = next(idx for idx,l in enumerate(lines) if l.strip() == 'flutter:')
except StopIteration:
    # Append at end
    lines.append('\nflutter:\n')
    fi = len(lines)-1

# Determine if assets: exists within flutter section
# Flutter section ends at next top-level key
fj = fi + 1
while fj < len(lines):
    l = lines[fj]
    if l and not l.startswith(' ') and l.rstrip().endswith(':'):
        break
    fj += 1

flutter_text = ''.join(lines[fi:fj])
if '  assets:' not in flutter_text:
    # Insert assets after flutter: line
    insert_at = fi + 1
    lines[insert_at:insert_at] = ['  assets:\n'] + [a+'\n' for a in assets]
else:
    # Append missing asset entries
    for a in assets:
        if a not in flutter_text:
            # Insert before flutter section end
            lines[fj:fj] = [a+'\n']
            fj += 1

pub.write_text(''.join(lines), encoding='utf-8')
PY

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
