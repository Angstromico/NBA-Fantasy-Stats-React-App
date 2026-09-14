# NBA Fantasy Stats Tracker (Flutter)

A Flutter port of the React NBA Fantasy Stats app — track games, view
milestones, records, and leaderboards with a glassmorphism UI.

## Getting Started

```bash
flutter pub get
flutter run
```

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/get-started/learn-flutter).

## Building a Release

### 1. Signing key

The release keystore (`android/app/nba_fantasy.jks`) and its credentials
(`android/key.properties`) are **not committed** — `android/.gitignore`
excludes `key.properties`, `**/*.jks`, and `**/*.keystore`.

To create them on a new machine:

```bash
# 1. Generate the keystore (choose your own passwords)
"/c/Program Files/Android/Android Studio/jbr/bin/keytool.exe" -genkey -v \
  -keystore android/app/nba_fantasy.jks \
  -alias nba_fantasy \
  -keyalg RSA -keysize 2048 \
  -validity 10000

# 2. Write android/key.properties (git-ignored):
#    storePassword=<your_store_password>
#    keyPassword=<your_key_password>   # must equal storePassword for PKCS12
#    keyAlias=nba_fantasy
#    storeFile=nba_fantasy.jks
```

> ⚠️ Losing the keystore means you cannot publish updates to the same Play
> Store listing. Back it up somewhere safe (not in this repo).

Without `key.properties`, release builds fall back to debug signing so
`flutter run --release` still works locally.

### 2. Build

```bash
# Signed APK for sideloading
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# App Bundle for Play Store upload
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 3. Quality checks before a release

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed lib/
```

R8 minification (`isMinifyEnabled`) and resource shrinking
(`isShrinkResources`) are enabled for release builds via
`android/app/build.gradle.kts`.
