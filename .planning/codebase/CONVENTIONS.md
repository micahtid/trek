# Coding Conventions

**Analysis Date:** 2026-02-27

## Naming Patterns

**Files:**
- Snake_case for Dart files: `main.dart`, `widget_test.dart`
- State classes use underscore prefix: `_NotesListPageState`, `_NoteEditorPageState`

**Classes:**
- PascalCase for all classes: `Note`, `NotesApp`, `NotesListPage`, `NoteEditorPage`
- State classes prefix with underscore: `_NotesListPageState`
- Widget classes don't use prefixes: `NotesApp`, `NotesListPage`

**Functions:**
- camelCase for function names: `_openNote()`, `_addNewNote()`, `_formatDate()`, `_persist()`
- Private functions use leading underscore: `_openNote()`, `_formatDate()`, `_getBorderRadius()`
- Public lifecycle methods use standard Dart conventions: `initState()`, `dispose()`, `build()`

**Variables:**
- camelCase for local and member variables: `_notes`, `deleted`, `bottomPad`, `preview`
- Private member variables use leading underscore: `_titleController`, `_contentController`, `_titleFocus`
- Constants use uppercase with underscores in some contexts, but inline constants use descriptive names: `const days = ['Monday', 'Tuesday', ...]`

**Types/Classes:**
- PascalCase for custom types: `Note` model class

## Code Style

**Formatting:**
- Standard Dart formatting (4-space indentation)
- No explicit formatter tool configured; uses Dart's built-in formatting conventions
- Single-line comments for inline explanations
- Multi-line comments for section headers using special formatting

**Linting:**
- Uses `flutter_lints` package (version ^6.0.0) from pubspec.yaml
- Includes `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`
- Custom rules can be configured by uncommenting in `analysis_options.yaml`
- Default Flutter lints enforced (recommended practices)

**Section Organization:**
- Code organized with visual section separators using comment headers:
  ```dart
  // ─── Model ────────────────────────────────────────────────────────────────────
  // ─── App ───────────────────────────────────────────────────────────────────────
  // ─── Notes List ────────────────────────────────────────────────────────────────
  // ─── Note Editor ───────────────────────────────────────────────────────────────
  ```
- Sections group related classes and functionality

## Import Organization

**Order:**
1. Package imports from Flutter and Flutter-related packages
2. Relative imports within the app (rare in this codebase as most code is in main.dart)

**Example:**
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
```

**Path Aliases:**
- Not used in this codebase (single-file app structure)

## Error Handling

**Patterns:**
- No explicit error handling framework visible
- Validation done inline: `if (widget.note.title.isEmpty && widget.note.content.isEmpty)`
- Confirmations use Cupertino dialogs: `showCupertinoDialog()` for destructive actions
- Null safety enforced with required fields in constructors

**Dialog Handling:**
- Use `CupertinoAlertDialog` for iOS-style confirmations in `_confirmDelete()`
- Navigate using `Navigator.of(context)` for both push/pop operations
- Provide user feedback before destructive operations

## Logging

**Framework:** None detected. Uses standard Dart/Flutter print() approach (not explicitly used in this codebase).

**Patterns:**
- No explicit logging framework configured
- Comments used to document significant operations
- Debug info relies on Flutter's built-in debugging tools

## Comments

**When to Comment:**
- Used sparingly for non-obvious logic
- Section headers use decorative comment lines with emoji-like separators
- Comments explain the "why" rather than the "what"

**Examples:**
```dart
// Auto-focus title field for new notes
if (widget.note.title.isEmpty && widget.note.content.isEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocus.requestFocus());
}

// Format date like iOS Notes: time today, weekday this week, date otherwise
String _formatDate(DateTime date) {
```

**JSDoc/TSDoc:**
- Not used in Dart (Dart uses dartdoc)
- No explicit documentation comments (///) observed in this codebase
- Dart convention allows /// for public API documentation

## Function Design

**Size:** Functions are kept moderately sized
- Date formatting function: 19 lines
- Note opening function: 22 lines
- Persist function: 7 lines
- Private helper methods extracted for reusability

**Parameters:**
- Use named parameters with `required` keyword for clarity
- Example from `Note` constructor:
  ```dart
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modifiedAt,
  });
  ```
- Widget constructors follow Flutter convention with `super.key`

**Return Values:**
- Functions return appropriate types: `String`, `BorderRadius`, `void`
- Future-returning async functions used for navigation: `Future<void> _openNote(Note note)`
- Callbacks use `VoidCallback` type for simple void callbacks

## Module Design

**Exports:**
- All classes are top-level (no explicit library exports)
- Single-file architecture in `main.dart` contains entire app

**Barrel Files:**
- Not applicable (monolithic single-file structure)

**State Management Pattern:**
- Uses StatefulWidget and State<T> pattern
- Mutable state stored in State class members
- setState() used to trigger rebuilds
- Local state controllers (TextEditingController, FocusNode) managed in dispose()

## Widget and UI Patterns

**Widget Hierarchy:**
- Widgets nested logically within build() methods
- Large nested structures broken into logical sections with comments
- Color values defined inline as hex codes: `const Color(0xFFF2F2F7)`

**Material/Cupertino:**
- Mixed use of Material (Scaffold, AppBar, TextField, Divider) and Cupertino (CupertinoButton, CupertinoIcons, CupertinoAlertDialog, CupertinoPageRoute)
- iOS-style navigation using CupertinoPageRoute
- iOS-style dialogs for confirmations

---

*Convention analysis: 2026-02-27*
