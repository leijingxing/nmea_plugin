# Gemini Project Configuration

## Project Overview

This project is a Flutter plugin named `nmea_plugin`. Based on the name and typical structure, its purpose is likely to parse NMEA (National Marine Electronics Association) data sentences, commonly used by GPS receivers, for use in a Flutter application.

## Technology Stack

- **Framework**: Flutter
- **Languages**:
    - Dart (primary plugin and application logic)
    - Kotlin (Android platform-specific implementation)
    - Swift (iOS platform-specific implementation)

## Project Structure

- `lib/`: Contains the core Dart code for the plugin.
- `android/`: Contains the Android-specific implementation (Kotlin).
- `ios/`: Contains the iOS-specific implementation (Swift).
- `example/`: Contains an example Flutter application that demonstrates how to use the plugin.
- `pubspec.yaml`: Defines the plugin's dependencies and metadata.
- `analysis_options.yaml`: Configures static analysis and linting rules for Dart.

## Development Workflow

### Key Commands

- **Get dependencies**: `flutter pub get`
- **Run tests**: `flutter test`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`
- **Run the example app**: `cd example && flutter run`

### Commit Messages

When committing changes, please follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This helps maintain a clear and automated version history.

- **Examples**:
    - `feat: Add support for GGA sentences`
    - `fix: Correctly parse checksums with leading zeros`
    - `docs: Update README with usage instructions`
    - `refactor: Improve performance of the NMEA parser`
