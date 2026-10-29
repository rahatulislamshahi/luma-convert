# Luma Convert

Luma Convert is an offline unit converter for Android, built with Flutter and Dart. It uses a glass-inspired interface and keeps saved conversions and preferences on the device.

Version: 1.0.2

## Features

- 47 units across length, weight, temperature, area, volume, speed, data and time
- Dark and light themes
- Swappable input and output units
- Decimal precision from 2 to 12 places
- Favorite categories move to the front of the category list
- Recent conversion history with one-tap reuse
- Copy result to the clipboard
- Responsive portrait and landscape layouts
- Local storage with no network requirement

## Requirements

- Flutter 3.35.5 with Dart 3.9.2
- Android Studio with the Flutter and Dart plugins
- A full JDK 17 or 21, including the Java compiler
- Android SDK Platform 36 and Build-Tools 35.0.0
- Android NDK 27.0.12077973
- CMake 3.22.1 if requested by the Android build tools

Minimum Android version: Android 7.0, API 24.

Supported processor architectures: ARMv7 (`armeabi-v7a`), ARM64 (`arm64-v8a`) and x86_64. Android 6 and earlier, and 32-bit x86 devices, are not supported by this Flutter version.

## Run the app

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Open the folder containing `pubspec.yaml` in Android Studio. Android Studio will create `android/local.properties` for the Flutter and Android SDK paths on the local machine.

Enter a value and select the source and destination units. Results update immediately. Tap Save to add a conversion to history, or use the clipboard button to copy the result. A comma is accepted as a decimal separator; grouping separators are not supported. Very small results use scientific notation instead of rounding to zero. Temperatures below absolute zero are rejected.

## Build an APK

```bash
flutter build apk --release
```

The APK is created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For architecture-specific APKs:

```bash
flutter build apk --release --split-per-abi
```

The default signing configuration uses a debug key for local APK testing. For a store release, create an upload keystore and an `android/key.properties` file with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`. The Gradle configuration uses that key when the file exists. Keep the keystore and passwords outside version control.

## Verification

The automated suite covers 295 unit-pair round trips, input validation, numeric formatting, swap accuracy, saved preferences, history reuse, storage failures, clipboard actions and dropdown controls. Layout tests cover 12 logical screen sizes from 240×480 to 1280×800 at normal, double and triple text size: 36 combinations, including settings and history sheets. Rotation, display cutouts and portrait and landscape keyboard insets are also covered.

Run Android lint from the Android directory:

```bash
cd android
./gradlew lintRelease
```

On Windows PowerShell, use `.\gradlew.bat lintRelease` instead.

Automated checks do not replace testing on physical devices. Android versions, manufacturer firmware, GPUs and keyboards vary; compatibility with every Android phone cannot be guaranteed.

Run `flutter analyze` and `flutter test` after making changes. The app uses Dart double precision; results are intended for everyday conversions rather than arbitrary-precision calculations.

## Project structure

```text
lib/core/  conversion engine, controller and local storage
lib/ui/    glass interface, palette and responsive screens
test/      engine, controller, widget and responsive tests
android/   Android configuration, storage bridge and launcher icon
```

The release app does not request internet access or Android cloud backup. Uninstalling the app removes its saved data.
