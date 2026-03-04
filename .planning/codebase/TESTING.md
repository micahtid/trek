# Testing Patterns

**Analysis Date:** 2026-02-27

## Test Framework

**Runner:**
- Flutter testing framework (flutter_test SDK package)
- Built into Flutter SDK
- Config: `pubspec.yaml` includes `flutter_test` under dev_dependencies

**Assertion Library:**
- Flutter's built-in `expect()` function from `flutter_test` package

**Run Commands:**
```bash
flutter test                          # Run all tests
flutter test --watch                 # Watch mode
flutter test --coverage               # Generate coverage report
flutter test test/widget_test.dart   # Run specific test file
```

## Test File Organization

**Location:**
- Tests co-located in `test/` directory at project root
- Follows Dart/Flutter convention of separate test directory
- Test file: `test/widget_test.dart`

**Naming:**
- Files named with `_test.dart` suffix
- Test class uses `testWidgets()` for widget tests

**Structure:**
```
intern_tracker/
├── test/
│   └── widget_test.dart        # All widget tests for the app
├── lib/
│   └── main.dart               # Application source
└── pubspec.yaml
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  testWidgets('Test description', (WidgetTester tester) async {
    // Setup
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    // Interactions and assertions
    expect(find.text('Grocery List'), findsOneWidget);
  });
}
```

**Patterns:**
- Setup: Each test starts with `tester.pumpWidget()` to render the app
- Pump: Uses `tester.pumpAndSettle()` to settle widget animations and layouts
- Interaction: Uses `tester.tap()` to simulate user interactions
- Assertion: Uses `expect()` with find patterns to verify UI state

## Widget Finding and Interaction

**Finding Widgets:**
```dart
// By text content
find.text('Grocery List')

// By icon
find.byIcon(CupertinoIcons.square_pencil)

// Generic widget tree search
find.byType(NotesApp)
```

**Common Assertions:**
```dart
// Verify widget appears exactly once
expect(find.text('Grocery List'), findsOneWidget);

// Alternative matchers (not used in current tests but available)
findsNothing    // Widget not found
findsWidgets    // One or more widgets found
```

**Interaction Patterns:**
```dart
// Tap gesture
await tester.tap(find.text('Grocery List'));

// Wait for animations and layout to settle
await tester.pumpAndSettle();
```

## Mocking

**Framework:** Flutter's built-in mocking via `WidgetTester` (no external mocking library like Mockito used)

**Patterns:**
- No explicit mocking of dependencies
- Direct widget testing with full integration (NotesApp rendered completely)
- State verified through UI element presence and text content

**What to Mock:**
- In current tests: nothing is mocked
- For future tests with external dependencies (API calls, storage), would use `mockito` package

**What NOT to Mock:**
- Widget rendering (test real widgets)
- Navigation (test real navigation flows)
- State management (test actual StatefulWidget state changes)

## Fixtures and Factories

**Test Data:**
- Pre-populated sample notes hardcoded in `_NotesListPageState` constructor
- Test data approach: render app with existing sample notes
- No separate fixture files or factory functions currently used

**Test Example:**
```dart
testWidgets('Notes list renders with pre-populated notes', (WidgetTester tester) async {
  await tester.pumpWidget(const NotesApp());
  await tester.pumpAndSettle();

  // Verify sample notes are visible
  expect(find.text('Grocery List'), findsOneWidget);
  expect(find.text('Project Ideas'), findsOneWidget);
  expect(find.text('Meeting Notes'), findsOneWidget);
  expect(find.text('Book Recommendations'), findsOneWidget);
});
```

**Location:**
- Test data embedded in the application code (`lib/main.dart`)
- Sample notes created in `_NotesListPageState._notes` initialization

## Coverage

**Requirements:** Not enforced (no coverage configuration in `analysis_options.yaml`)

**View Coverage:**
```bash
flutter test --coverage
# Generates coverage report in coverage/lcov.info
# Use tools like lcov or Codecov to view detailed coverage
```

**Current State:**
- No coverage thresholds defined
- Basic widget tests provide some coverage of main flows

## Test Types

**Unit Tests:**
- Not present in current codebase
- Would test: date formatting logic, note filtering, data manipulation
- Example candidates: `_formatDate()`, note persistence logic

**Widget Tests:**
- Primary test type: `flutter_test` widget tests
- Scope: Full app rendering with user interactions
- Current tests: 4 widget tests covering major user flows
- Approach: Render full NotesApp, simulate user actions, verify UI state

**Integration Tests:**
- Not currently implemented
- Would require separate `integration_test/` directory
- Would test multi-screen flows, navigation, state persistence

**E2E Tests:**
- Not used (Flutter integration_test framework available if needed)

## Current Test Coverage

**Location:** `test/widget_test.dart`

**Test Cases:**

1. **Test: Notes list renders with pre-populated notes**
   - Verifies 4 sample notes display in the list
   - Asserts: `expect(find.text('Grocery List'), findsOneWidget)` and 3 others
   - Coverage: Initial app state, list rendering

2. **Test: Tapping compose button creates a new note**
   - Taps the compose icon (CupertinoIcons.square_pencil)
   - Verifies navigation to editor with Done button visible
   - Coverage: New note creation flow

3. **Test: Tapping a note opens the editor with its content**
   - Taps a note in the list
   - Verifies editor displays with note title and Done button
   - Coverage: Note opening, editor display

4. **Test: Done button returns to the notes list**
   - Opens a note, then taps Done
   - Verifies back navigation to list (large title visible)
   - Coverage: Navigation flow

## Gaps in Testing

**Untested Functionality:**
- Note editing: Title and content modification
- Note deletion: Delete confirmation dialog and removal
- Note persistence: Changes saved when editor closed
- Date formatting edge cases: Same day, yesterday, older dates
- Empty note handling: Removing empty notes
- Sorting behavior: Notes sorted by modification date
- Multi-note interactions: Creating multiple notes, ordering

**Critical Gaps:**
- No tests for note content persistence on close
- No tests for delete confirmation dialog
- No tests for date formatting logic (`_formatDate()`)
- No unit tests for business logic

## Testing Best Practices to Follow

**For new tests:**
1. Use `testWidgets()` for UI-related functionality
2. Always call `tester.pumpAndSettle()` after interactions to wait for animations
3. Use `find.text()` or `find.byIcon()` for widget discovery
4. Test user-visible behavior, not implementation details
5. Group related tests in `main()` function
6. Use descriptive test names that explain what is tested

**File location:**
- Place tests in `test/` directory with `_test.dart` suffix
- Keep test file structure flat or organize by feature if multiple files added

---

*Testing analysis: 2026-02-27*
