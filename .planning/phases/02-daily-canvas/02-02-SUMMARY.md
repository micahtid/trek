---
phase: 02-daily-canvas
plan: 02
subsystem: ui
tags: [flutter, riverpod, material3, speech-to-text, bottom-sheet, card-feed, voice-input]

# Dependency graph
requires:
  - phase: 02-daily-canvas
    plan: 01
    provides: Entry model, EntryRepository CRUD, todayEntriesProvider real-time stream, currentUserIdProvider
provides:
  - TodayScreen card-stream feed with real-time entry display, empty/loading/error states, and FAB
  - EntryCard reusable widget with text preview, formatted timestamp, and voice mic badge
  - ComposeSheet bottom sheet with multiline text input, speech_to_text voice dictation, and save action
  - EntryDetailScreen with read/edit toggle, delete with undo snackbar
affects: [02-03-PLAN (search wiring on TodayScreen AppBar)]

# Tech tracking
tech-stack:
  added: []
  patterns: [showModalBottomSheet with isScrollControlled for keyboard-aware bottom sheets, speech_to_text initialize/listen/stop lifecycle, ScaffoldMessenger captured before Navigator.pop for cross-screen snackbar, ConsumerStatefulWidget for speech state management]

key-files:
  created:
    - lib/features/today/presentation/entry_card.dart
    - lib/features/today/presentation/compose_sheet.dart
    - lib/features/today/presentation/entry_detail_screen.dart
  modified:
    - lib/features/today/today_screen.dart
    - android/app/src/main/AndroidManifest.xml

key-decisions:
  - "EntryCard uses Card with surfaceContainerLow fill (not elevated shadow) for clean M3 aesthetic"
  - "ComposeSheet tracks _inputMethod starting as 'text', switching to 'voice' on mic use, never reverting — original input method is preserved"
  - "Delete uses immediate delete + undo re-create pattern (new _id/timestamp acceptable for few-second undo window)"
  - "ScaffoldMessenger captured before Navigator.pop to show undo snackbar on parent screen after popping detail"
  - "Delete has a confirmation dialog before executing — safety net before the undo safety net"

patterns-established:
  - "showModalBottomSheet with isScrollControlled: true for any keyboard-interactive bottom sheet"
  - "speech_to_text lifecycle: initialize once, toggle listen/stop, track _isListening state"
  - "Capture ScaffoldMessenger.of(context) before Navigator.pop for cross-screen snackbar display"
  - "Entry detail as Navigator.push MaterialPageRoute (not GoRouter) for transient views"

requirements-completed: [CANV-01, CANV-03, CANV-05]

# Metrics
duration: 4min
completed: 2026-03-03
---

# Phase 02 Plan 02: Daily Canvas UI Summary

**Card-stream feed with FAB compose sheet (text + voice via speech_to_text), entry cards with timestamp and mic badge, and detail screen with edit/delete/undo snackbar**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-03T21:47:52Z
- **Completed:** 2026-03-03T21:52:13Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Built TodayScreen card-stream feed watching todayEntriesProvider with empty state ("What did you work on today?"), loading spinner, and error retry
- Created ComposeSheet bottom sheet with multiline TextField, speech_to_text mic toggle with visual feedback, and save action calling entryRepositoryProvider.createEntry
- Created EntryCard with 2-3 line body preview, formatted timestamp (time-only for today, date+time for older), and mic badge for voice entries
- Built EntryDetailScreen with read/edit mode toggle, delete with confirmation dialog and 4-second undo snackbar that re-creates the entry

## Task Commits

Each task was committed atomically:

1. **Task 1: Build TodayScreen card feed with FAB, EntryCard, and ComposeSheet with voice input** - `6b30ded` (feat)
2. **Task 2: Build entry detail screen with edit, delete, and undo snackbar** - `def5644` (feat)

## Files Created/Modified
- `lib/features/today/today_screen.dart` - Rewrote placeholder to full card-stream canvas with FAB, empty/loading/error states
- `lib/features/today/presentation/entry_card.dart` - Reusable card widget with body preview, timestamp, voice mic badge
- `lib/features/today/presentation/compose_sheet.dart` - Bottom sheet with TextField, speech_to_text mic button, save action
- `lib/features/today/presentation/entry_detail_screen.dart` - Full entry view with edit toggle, delete with undo snackbar
- `android/app/src/main/AndroidManifest.xml` - Added RECORD_AUDIO permission for voice dictation

## Decisions Made
- EntryCard uses surfaceContainerLow fill color (not elevated shadow) for a clean Material 3 look
- ComposeSheet tracks inputMethod starting as "text", switching to "voice" on first mic use, never reverting back
- Delete flow: immediate deletion + undo snackbar re-creates entry (new _id/timestamp is acceptable for short undo window)
- Added confirmation dialog before delete as additional safety net
- ScaffoldMessenger captured before Navigator.pop to show undo snackbar on parent TodayScreen
- Entry detail uses Navigator.push (not GoRouter route) since it's a transient view, not a tab destination

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added RECORD_AUDIO permission to AndroidManifest.xml**
- **Found during:** Task 1 (ComposeSheet voice input setup)
- **Issue:** speech_to_text requires RECORD_AUDIO permission in AndroidManifest.xml but it was not present
- **Fix:** Added `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` to manifest
- **Files modified:** android/app/src/main/AndroidManifest.xml
- **Verification:** Permission present in manifest; plan explicitly called for this check
- **Committed in:** 6b30ded (Task 1 commit)

**2. [Rule 3 - Blocking] Created EntryDetailScreen stub for Task 1 compilation**
- **Found during:** Task 1 (TodayScreen imports EntryDetailScreen)
- **Issue:** TodayScreen imports EntryDetailScreen which doesn't exist yet (created in Task 2)
- **Fix:** Created minimal stub with constructor accepting Entry, replaced with full implementation in Task 2
- **Files modified:** lib/features/today/presentation/entry_detail_screen.dart
- **Verification:** dart analyze passes; stub fully replaced in Task 2
- **Committed in:** 6b30ded (Task 1 commit), fully replaced in def5644 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both auto-fixes necessary for correctness. RECORD_AUDIO was explicitly called for in the plan. Stub was a sequencing necessity. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Full daily canvas UI ready: feed, compose, detail, edit, delete with undo
- Search icon in AppBar is a placeholder — Plan 03 will wire it to searchEntries query
- Voice input pipeline complete: speech_to_text permission, initialization, listen/stop, transcription into TextField
- All providers from Plan 01 are consumed: todayEntriesProvider (feed), currentUserIdProvider (compose), entryRepositoryProvider (CRUD)

## Self-Check: PASSED

All 6 key files verified present on disk. Both task commits (6b30ded, def5644) verified in git log.

---
*Phase: 02-daily-canvas*
*Completed: 2026-03-03*
