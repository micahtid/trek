# Architecture

**Analysis Date:** 2026-02-27

## Pattern Overview

**Overall:** Monolithic Single-File Widget Architecture

**Key Characteristics:**
- All code contained in single entry point `lib/main.dart`
- Model-View-Controller pattern implemented inline with widgets
- Direct state management using StatefulWidget local state
- Material Design with iOS-style UI (Cupertino components)
- No separation of concerns or architectural layers

## Layers

**Model Layer:**
- Purpose: Data representation for notes
- Location: `lib/main.dart` (lines 10-22)
- Contains: `Note` class with properties (id, title, content, modifiedAt)
- Depends on: None (pure data class)
- Used by: `NotesListPage`, `NoteEditorPage` widgets

**View/UI Layer:**
- Purpose: Presentation logic and user interface rendering
- Location: `lib/main.dart` (entire file except model definition)
- Contains: Flutter widgets (`NotesApp`, `NotesListPage`, `NoteEditorPage`)
- Depends on: Model layer, Flutter framework
- Used by: Main entry point

**State Management Layer:**
- Purpose: In-memory data persistence and UI updates
- Location: `lib/main.dart` (`_NotesListPageState` class)
- Contains: Notes list, CRUD operations, sorting logic
- Depends on: Model layer
- Used by: `NotesListPage` widget

## Data Flow

**Note Creation Flow:**

1. User taps compose button (square_pencil icon)
2. `_addNewNote()` creates new `Note` instance with empty title/content
3. Note inserted at index 0 in `_notes` list
4. `setState()` triggers rebuild
5. Navigation to `NoteEditorPage` with note reference
6. User edits title and content, triggering `_persist()` on every keystroke
7. User taps "Done" button to close editor
8. If note is empty (title and content both empty), removed from list
9. List re-sorted by `modifiedAt` timestamp descending
10. Back on list view with updated note

**Note Deletion Flow:**

1. User taps trash icon in editor
2. `_confirmDelete()` shows Cupertino confirmation dialog
3. User confirms delete
4. `onDelete` callback executed, setting `deleted = true`
5. Navigator pops editor
6. `setState()` in list page checks `deleted` flag
7. Note removed from `_notes` list
8. List re-sorted and UI rebuilt

**State Management:**
- Notes stored as `List<Note>` in `_NotesListPageState._notes`
- Modifications directly mutate note objects or list
- Changes persisted via `setState()` which rebuilds entire widget tree
- Data lost on app restart (in-memory only, no persistence layer)

## Key Abstractions

**Note Model:**
- Purpose: Represents a single note with metadata
- Examples: `lib/main.dart` lines 10-22
- Pattern: Simple PODO (Plain Old Dart Object) with properties and constructor

**NotesListPage:**
- Purpose: Root screen displaying list of all notes
- Examples: `lib/main.dart` lines 46-343
- Pattern: StatefulWidget holding shared state for entire app

**NoteEditorPage:**
- Purpose: Modal editor for viewing and editing individual notes
- Examples: `lib/main.dart` lines 347-593
- Pattern: Cupertino-style navigation modal with lifecycle callbacks

## Entry Points

**Application Root:**
- Location: `lib/main.dart` (lines 1-6)
- Triggers: `flutter run` entry point
- Responsibilities: Initializes and runs `NotesApp` widget

**NotesApp Widget:**
- Location: `lib/main.dart` (lines 26-42)
- Triggers: Application startup
- Responsibilities: Configures Material theme, sets home screen to `NotesListPage`

**NotesListPage:**
- Location: `lib/main.dart` (lines 46-343)
- Triggers: App initialization or navigation back from editor
- Responsibilities: Renders notes list, handles compose button, manages navigation

## Error Handling

**Strategy:** No explicit error handling implemented

**Patterns:**
- No try-catch blocks
- No error dialogs or fallback UI
- Dialog only used for delete confirmation, not error states
- Relies on Flutter framework defaults for runtime errors

## Cross-Cutting Concerns

**Logging:** No logging implemented. Debug output relies on Flutter inspector and console.

**Validation:**
- Title trimmed before persistence: `_titleController.text.trim()`
- Empty notes deleted automatically (title and content both empty)
- No input validation (character limits, forbidden characters, etc.)

**Authentication:** Not applicable. Single-user local app.

**UI Consistency:**
- Color scheme: Amber seed color from Material 3 theme
- Font: `.SF Pro Text` (San Francisco system font for iOS integration)
- Spacing: Consistent padding values (8, 12, 16px)
- Icons: Mix of Cupertino icons and standard Material icons
- iOS-style large title in app bar using `SliverAppBar.large`
- Bottom toolbars styled as iOS Notes clone

---

*Architecture analysis: 2026-02-27*
