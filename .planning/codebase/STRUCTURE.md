# Codebase Structure

**Analysis Date:** 2026-02-27

## Directory Layout

```
intern_tracker/
├── lib/                    # Dart source code
│   └── main.dart          # Entire application (single file)
├── test/                  # Test files
│   └── widget_test.dart   # Widget tests
├── android/               # Android platform-specific code (generated)
├── ios/                   # iOS platform-specific code (generated)
├── macos/                 # macOS platform-specific code (generated)
├── linux/                 # Linux platform-specific code (generated)
├── windows/               # Windows platform-specific code (generated)
├── web/                   # Web platform-specific code (generated)
├── build/                 # Build output (generated)
├── .dart_tool/            # Dart tooling cache (generated)
├── .idea/                 # IDE configuration (IntelliJ/Android Studio)
├── pubspec.yaml           # Package manifest and dependencies
├── pubspec.lock           # Locked dependency versions
├── analysis_options.yaml  # Dart analyzer configuration
├── .metadata              # Flutter project metadata
├── .gitignore             # Git ignore rules
└── README.md              # Project documentation
```

## Directory Purposes

**lib/**
- Purpose: All Dart source code for the Flutter application
- Contains: Single application file with models, views, and state management
- Key files: `main.dart`

**test/**
- Purpose: Widget tests and integration tests
- Contains: Flutter widget tests using `flutter_test` framework
- Key files: `widget_test.dart`

**android/**, **ios/**, **macos/**, **linux/**, **windows/**, **web/**
- Purpose: Platform-specific implementations and configurations
- Contains: Generated platform adapters, native code stubs, web assets
- Key files: Gradle files (Android), Xcode project files (iOS), manifest files

**build/**
- Purpose: Build output directory
- Contains: Compiled artifacts, asset manifests, generated files
- Generated: Yes
- Committed: No

**.dart_tool/**
- Purpose: Dart tooling and package management cache
- Contains: Package configurations, dependency graphs
- Generated: Yes
- Committed: No

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Application root with `void main()` function

**Configuration:**
- `pubspec.yaml`: Package dependencies, app metadata, asset declarations
- `pubspec.lock`: Locked versions for reproducible builds
- `analysis_options.yaml`: Dart linter and analyzer configuration

**Core Logic:**
- `lib/main.dart`: Model, presentation, and state management (all in one file)
  - Lines 8-22: `Note` model class
  - Lines 24-42: `NotesApp` root widget with theme configuration
  - Lines 44-343: `NotesListPage` with list rendering and CRUD operations
  - Lines 345-593: `NoteEditorPage` with editing interface

**Testing:**
- `test/widget_test.dart`: Four widget tests covering navigation and composition

## Naming Conventions

**Files:**
- Dart files: `snake_case.dart` (e.g., `main.dart`, `widget_test.dart`)
- Single app file: `main.dart` containing all application code

**Directories:**
- Lowercase with underscores: `lib`, `test`, `.dart_tool`
- Platform platform names match Flutter conventions: `android`, `ios`, `web`, etc.

**Classes:**
- PascalCase: `Note`, `NotesApp`, `NotesListPage`, `NoteEditorPage`, `_NotesListPageState`, `_NoteEditorPageState`
- Private state classes prefixed with underscore: `_NotesListPageState`

**Methods:**
- camelCase: `_openNote()`, `_addNewNote()`, `_formatDate()`, `_getBorderRadius()`, `_persist()`, `_confirmDelete()`, `_headerDate()`
- Private methods prefixed with underscore: `_openNote`, `_persist`

**Variables:**
- camelCase: `note`, `preview`, `bottomPad`, `h`, `m`, `p`, `deleted`, `today`, `noteDay`, `diff`
- Private variables prefixed with underscore: `_notes`, `_titleController`, `_contentController`, `_titleFocus`, `_contentFocus`

**Constants:**
- camelCase for final variables: `const months = [...]`, `const days = [...]`
- Inline magic numbers used for colors, sizes, durations (not extracted as named constants)

## Where to Add New Code

**New Feature:**
- Primary code: `lib/main.dart` (currently all features here)
- Tests: `test/widget_test.dart` (add test cases to existing file)
- Recommendation: Create separate feature modules instead (e.g., `lib/pages/`, `lib/models/`, `lib/widgets/`)

**New Component/Module:**
- Implementation: Create new `.dart` file in `lib/` directory
- Pattern: Follow StatelessWidget or StatefulWidget pattern
- Export: Import in `lib/main.dart` or create barrel file (`lib/widgets.dart`)
- Recommendation: Organize by feature (e.g., `lib/features/notes/widgets/`, `lib/features/notes/models/`)

**Utilities:**
- Shared helpers: Create `lib/utils/` directory for formatting, validation, constants
- Example: Extract `_formatDate()` and `_headerDate()` to `lib/utils/date_formatter.dart`

**Tests:**
- Co-located: Place tests in `test/` directory with `_test.dart` suffix
- Structure: Mirror `lib/` structure (e.g., `test/features/notes/widget_test.dart`)
- Current pattern: Single `widget_test.dart` file for all tests

## Special Directories

**build/**
- Purpose: Contains compiled Flutter app artifacts
- Generated: Yes
- Committed: No (listed in .gitignore)

**.dart_tool/**
- Purpose: Package dependency cache and metadata
- Generated: Yes
- Committed: No (listed in .gitignore)

**android/, ios/, macos/, linux/, windows/, web/**
- Purpose: Platform-specific native code and configurations
- Generated: Partially (scaffolding generated, but includes customizable native code)
- Committed: Yes (for build reproducibility)

---

*Structure analysis: 2026-02-27*
