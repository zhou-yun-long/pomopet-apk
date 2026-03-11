# Pomopet CI APK builder

This package provides a GitHub Actions workflow to build an Android debug APK for Pomopet without requiring local Flutter installation.

## What it now covers
- Today / Timer / Pet / Settings app skeleton
- proof screenshot entry via `image_picker`
- shop / inventory / equip flow
- persisted local settings
- streak sync and theme switch

## How to use
1. Create a new GitHub repo and push this folder contents.
2. Run the workflow **Build Android APK** in GitHub Actions.
3. Download these artifacts as needed:
   - `pomopet-debug-apk`
   - `pomopet-generated-project`
   - `pomopet-build-logs`

## Output
- `app-debug.apk`
- generated Flutter project snapshot
- analyze / build logs for debugging CI failures

## Note
The workflow generates a Flutter project, injects `pomopet_blueprint`, patches dependencies/assets, runs Drift codegen, runs `flutter analyze`, and then builds the debug APK.
