# Codebase Concerns

**Analysis Date:** 2026-02-27

## Tech Debt

**No Data Persistence Layer:**
- Issue: All notes exist only in memory using a List<Note> in _NotesListPageState. When the app closes or is killed, all data is lost permanently.
- Files: `lib/main.dart` (lines 54-79, 392-398)
- Impact: App is non-functional for real-world use. Users cannot save notes between sessions. The `_persist()` method only updates the in-memory Note object, not persistent storage.
- Fix approach: Implement a persistence layer using either SharedPreferences (for simple key-value storage), Hive (for local database), or sqflite (for SQLite). Add methods to serialize Note objects to JSON and save to device storage. Load notes from storage in initState of NotesListPage.

**Hardcoded Sample Data:**
- Issue: Four hardcoded notes are initialized in the List constructor with fixed IDs and dates.
- Files: `lib/main.dart` (lines 55-79)
- Impact: Cannot be removed by the user without code changes. Takes up memory and clutters the UI on fresh installs. Makes testing difficult.
- Fix approach: Remove hardcoded notes and load actual user notes from persistence. Add sample notes only on first app launch if persistence is empty.

**ID Generation Using Timestamp:**
- Issue: New note IDs are generated using `DateTime.now().millisecondsSinceEpoch.toString()` (line 106). This is not collision-proof if two notes are created within the same millisecond.
- Files: `lib/main.dart` (line 106)
- Impact: Potential data loss or corruption if notes with identical IDs are created. UUID or database autoincrement would be safer.
- Fix approach: Use uuid package to generate proper UUIDs, or rely on database autoincrement IDs if using a local database.

**Monolithic Single File:**
- Issue: All code (models, UI screens, business logic) is in a single `main.dart` file spanning 594 lines.
- Files: `lib/main.dart`
- Impact: Difficult to maintain, reuse, and test. Widget tree is deeply nested. No separation of concerns. Hard to follow data flow.
- Fix approach: Split into separate files: `lib/models/note.dart`, `lib/screens/notes_list_page.dart`, `lib/screens/note_editor_page.dart`, `lib/services/note_service.dart`. Consider using a state management solution (Provider, Riverpod, GetX).

## Known Bugs

**Date/Time Display Bug - 24-Hour vs 12-Hour Format:**
- Symptoms: Both `_formatDate()` (line 116) and `_headerDate()` (line 425) use `date.hour % 12` to convert to 12-hour format. When hour is 0 (midnight), `0 % 12 = 0`, which displays as "0:XX AM" instead of "12:XX AM". Same issue for noon (12 % 12 = 0).
- Files: `lib/main.dart` (lines 123, 430)
- Trigger: Create or modify a note at midnight (00:XX) or noon (12:XX) and view its timestamp.
- Workaround: The bug only affects display; the actual time is correct. Users will see "0:15 AM" instead of "12:15 AM".
- Fix approach: Replace `date.hour % 12 == 0 ? 12 : date.hour % 12` with proper logic: `date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour)`

**Delete Callback Not Validated:**
- Symptoms: The `deleted` variable in `_openNote()` (line 82) is set by the editor's `onDelete` callback, but there's a race condition if multiple delete operations happen rapidly.
- Files: `lib/main.dart` (lines 81-102)
- Trigger: Rapidly open and delete multiple notes in succession.
- Workaround: The bug is unlikely in normal usage, but theoretically could cause inconsistent state.
- Fix approach: Use a proper return value from the editor instead of relying on a mutable closure variable. Use sealed result types or enums.

## Security Considerations

**No Input Validation:**
- Risk: Note titles and content accept any input with no validation or sanitization. While this is a local app, if extended to sync with cloud services, unsanitized input could cause issues.
- Files: `lib/main.dart` (lines 505-527, 538-560)
- Current mitigation: None. App only runs locally with no network connectivity currently.
- Recommendations: Add input validation (max length, character restrictions) in Note model validation. If adding cloud sync, implement proper sanitization.

**No Data Encryption:**
- Risk: Notes stored on disk (when persistence is added) will be stored in plaintext by default.
- Files: `lib/main.dart` (no current file affected; future persistence layer risk)
- Current mitigation: None. Relies on device's OS-level file permissions.
- Recommendations: If sensitive data is stored, implement encryption at rest using flutter_secure_storage for sensitive fields or encrypt entire database.

**No Access Control:**
- Risk: Any code or malware with device access can read all notes.
- Files: All of `lib/main.dart` (future persistence layer)
- Current mitigation: None.
- Recommendations: Consider implementing app-level authentication (PIN/biometric) if notes contain sensitive information. Use platform-specific secure storage.

## Performance Bottlenecks

**List Sorting on Every Navigation:**
- Problem: Every time a note is edited, `_notes.sort()` is called in setState (line 100). For large note counts (1000+), this becomes inefficient.
- Files: `lib/main.dart` (lines 96-101)
- Cause: The sort is O(n log n) and happens on every note update, even if just one character changed.
- Improvement path: Maintain sorted order during insertion/update instead of re-sorting. Use a data structure that maintains order (e.g., SortedList from collection package) or only sort when necessary.

**Full List Rebuild on Edit:**
- Problem: setState() is called with the entire _notes list when a single note is edited. Flutter rebuilds the entire list view.
- Files: `lib/main.dart` (lines 96-102)
- Cause: setState triggers rebuild of NotesListPage, which rebuilds all SliverList items even if only one note's modifiedAt changed.
- Improvement path: Use a state management library (Provider, Riverpod) to rebuild only affected list items. Alternatively, use ValueNotifier for individual note updates.

**SliverChildBuilderDelegate Without Estimated Child Count:**
- Problem: SliverChildBuilderDelegate (line 198) doesn't use `addAutomaticKeepAlives` or proper optimization flags.
- Files: `lib/main.dart` (lines 197-285)
- Cause: Can cause performance degradation with very large lists (100+ notes) due to widget lifecycle overhead.
- Improvement path: Add `addAutomaticKeepAlives: false, addRepaintBoundaries: true` parameters. Consider using SliverChildListDelegate if the list is stable.

## Fragile Areas

**Temporal Logic in Date Formatting:**
- Files: `lib/main.dart` (lines 115-135, 425-434)
- Why fragile: Uses DateTime.now() as the reference point, which changes throughout the day. "Yesterday" logic will fail at midnight. Week boundary calculations are error-prone. Tests will be flaky if they check specific dates without mocking time.
- Safe modification: Extract date formatting into a separate utility class that accepts a reference time parameter. Mock time in tests. Add unit tests for edge cases (midnight transitions, week boundaries, month boundaries).
- Test coverage: No unit tests for date formatting logic. Tests only check that date appears in UI, not correct format.

**Closure-based State Management in _openNote:**
- Files: `lib/main.dart` (lines 81-102)
- Why fragile: Uses a mutable `deleted` boolean to communicate state between pages. If navigation stack is corrupted or page is popped unexpectedly, state can be inconsistent.
- Safe modification: Use structured result types instead of closures. Return an enum or sealed class from Navigator.push indicating (Deleted, Saved, Discarded).
- Test coverage: Tests don't verify the delete flow or state consistency after deletion.

**Hard-coded Colors and Magic Numbers:**
- Files: `lib/main.dart` (entire file)
- Why fragile: Colors (0xFFF2F2F7, 0xFFBCBCC0, etc.) are scattered throughout. FontSize, padding, and radius values are magic numbers. Changes to theme require editing multiple locations.
- Safe modification: Extract all colors, sizes, and spacing into a theme constants file (`lib/theme/app_theme.dart`). Use consistent spacing scale (8px multiples).
- Test coverage: Golden/screenshot tests would catch unintended visual changes.

## Scaling Limits

**In-Memory List Capacity:**
- Current capacity: Theoretically unlimited RAM, practically 1000-5000 notes before noticeable lag on older devices.
- Limit: Once persistence is added, querying 10,000+ notes from SQLite without pagination will cause memory spikes and UI jank.
- Scaling path: Implement pagination/lazy loading. Load only first 50 notes, load more on scroll. Add search/filtering to reduce result set.

**Timestamp Collision Risk:**
- Current capacity: Can create ~1000 notes per second before collision probability becomes significant.
- Limit: In real-world usage at 10 notes/day, no limit is reached. But if notes are imported/synced in bulk, collisions possible.
- Scaling path: Use UUID v4 (universally unique) or database autoincrement. Add uniqueness constraint to Note model.

## Dependencies at Risk

**No Database Library:**
- Risk: Must add a persistence library (Hive, sqflite, or SharedPreferences) which introduces new dependencies and potential breaking changes.
- Impact: No current impact (data loss is the bigger concern). Will block any production deployment.
- Migration plan: Choose library based on complexity needs: SharedPreferences (simple), Hive (typed + fast), sqflite (relational). Add migration path if switching later.

**No State Management Library:**
- Risk: As app grows (add categories, tags, search), the manual setState() approach will become unmaintainable.
- Impact: Currently manageable for 3 screens. At 10+ screens, will cause prop drilling and state synchronization bugs.
- Migration plan: Plan to introduce Provider or Riverpod once more features are added. Avoid large refactoring; add new features using state management, refactor old code gradually.

## Missing Critical Features

**Data Persistence:**
- Problem: Notes disappear on app restart. App is not functional for users.
- Blocks: Cannot ship to production. Cannot have real users.

**Search/Filter:**
- Problem: With 50+ notes, finding a specific note is impossible. No way to search by title or content.
- Blocks: App usability degrades with any reasonable note count.

**Note Categories/Folders:**
- Problem: All notes in one flat list. No way to organize.
- Blocks: Organization-focused use cases.

**Sync/Backup:**
- Problem: No way to back up notes or sync across devices.
- Blocks: Users risk losing work. Cannot build cross-platform ecosystem.

**Collaborative Editing:**
- Problem: Single-user only. No sharing.
- Blocks: Team/family use cases.

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: Date formatting logic, ID generation, note sorting, persistence (when added).
- Files: `lib/main.dart` (entire model and business logic)
- Risk: Bugs in date formatting (like the 12-hour AM/PM issue) go undetected. Date edge cases (leap years, DST) not covered.
- Priority: High

**Widget Tests Only Cover Happy Path:**
- What's not tested: Error states, edge cases (empty notes, very long titles), concurrent edits, rapid navigation, deletion confirmation flow, undo/redo.
- Files: `test/widget_test.dart`
- Risk: Unknown bugs in UI behavior. Crashes or unexpected behavior in edge cases not covered by tests.
- Priority: High

**No Golden/Screenshot Tests:**
- What's not tested: Visual appearance consistency, layout correctness across screen sizes, dark mode (if added), accessibility.
- Files: No screenshot test file exists
- Risk: Unintended visual regressions go unnoticed. Layout breaks on tablets/foldables.
- Priority: Medium

**No Integration Tests:**
- What's not tested: Full end-to-end flows (create note → edit → delete → verify), persistence layer integration (when added), data sync workflows.
- Files: No integration test file exists
- Risk: Scenarios that work individually (create, edit) might fail in combination.
- Priority: Medium

---

*Concerns audit: 2026-02-27*
