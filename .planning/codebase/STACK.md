# Technology Stack

**Analysis Date:** 2026-02-27

## Languages

**Primary:**
- Dart 3.11.0+ - All application code, UI, and business logic

**Secondary:**
- None detected

## Runtime

**Environment:**
- Flutter 3.18.0+ - Cross-platform mobile development framework

**Package Manager:**
- Pub (Dart package manager) - Built-in package management system
- Lockfile: `pubspec.lock` - Present

## Frameworks

**Core:**
- Flutter 3.18.0+ - Mobile UI framework for Android, iOS, Linux, macOS, Windows, and web
- Material Design 3 - UI design system (via `material.dart`)
- Cupertino (iOS design) - Native iOS-style components (via `cupertino.dart`)

**Testing:**
- flutter_test - Built-in testing framework (SDK dependency)

**Build/Dev:**
- flutter_lints 6.0.0 - Linting rules and code analysis

## Key Dependencies

**Direct Dependencies:**
- cupertino_icons 1.0.8 - iOS-style icon set for Cupertino widgets
- flutter (SDK) - Core framework
- flutter_lints (SDK) - Development linting tools

**Transitive Dependencies:**
- async 2.13.0 - Async primitives and utilities
- boolean_selector 2.1.2 - Selector matching for tests
- characters 1.4.1 - Character utilities
- clock 1.1.2 - Time utilities
- collection 1.19.1 - Dart collection extensions
- fake_async 1.3.3 - Async testing utilities
- leak_tracker 11.0.2 - Memory leak detection
- leak_tracker_flutter_testing 3.0.10 - Flutter leak tracking
- leak_tracker_testing 3.0.2 - Testing leak tracker
- lints 6.1.0 - Lint rule definitions
- matcher 0.12.18 - Matcher library for assertions
- material_color_utilities 0.13.0 - Material color utilities
- meta 1.17.0 - Metadata annotations
- path 1.9.1 - Path manipulation utilities
- sky_engine - Flutter graphics engine
- source_span 1.10.2 - Source code span utilities
- stack_trace 1.12.1 - Stack trace utilities
- stream_channel 2.1.4 - Stream communication channels
- string_scanner 1.4.1 - String scanning utilities
- term_glyph 1.2.2 - Terminal glyphs
- test_api 0.7.9 - Testing API
- vector_math 2.2.0 - Vector and matrix math
- vm_service 15.0.2 - VM service protocol client

## Configuration

**Environment:**
- No environment variables required
- All configuration is code-based in `lib/main.dart`

**Build:**
- `pubspec.yaml` - Package manifest and Flutter configuration
- `analysis_options.yaml` - Dart analyzer and linter rules

## Platform Support

**Target Platforms:**
- Android (via `android/` directory)
- iOS (via `ios/` directory)
- Linux (via `linux/` directory)
- macOS (via `macos/` directory)
- Windows (via `windows/` directory)
- Web (via `web/` directory)

## Development Requirements

**Version Constraints:**
- Dart SDK: `^3.11.0` or higher
- Flutter: `>=3.18.0-18.0.pre.54`

**Build Output:**
- APK/AAB for Android
- IPA for iOS
- Executable for Linux/macOS/Windows
- Web bundle for web platform

## Material Design

**Theme Configuration:**
- Material Design 3 enabled (`useMaterial3: true`)
- Color scheme seed: Colors.amber
- Scaffold background: #F2F2F7 (light gray)
- Font family: '.SF Pro Text' (system font)

---

*Stack analysis: 2026-02-27*
