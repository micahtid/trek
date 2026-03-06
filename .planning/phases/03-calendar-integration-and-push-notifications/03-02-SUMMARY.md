---
phase: 03-calendar-integration-and-push-notifications
plan: "02"
subsystem: calendar, notifications, ui
tags: [google-calendar, riverpod, flutter-local-notifications, go-router, deep-linking, shared-preferences, material3]

# Dependency graph
requires:
  - phase: 03-calendar-integration-and-push-notifications
    plan: "01"
    provides: CalendarEvent model, CalendarEventRepository, calendar_providers, NotificationService, Entry.calendarEventId
  - phase: 02-daily-canvas
    provides: TodayScreen, ComposeSheet, EntryCard, entry_providers
  - phase: 01-foundation-and-auth
    provides: Google OAuth, GoRouter, AppShell, Settings screen
provides:
  - Collapsible AgendaSection widget with today's events and date-grouped missed events
  - EventCard widget with status indicators (upcoming/in_progress/ended/reflected/skipped) and swipe-to-skip
  - ComposeSheet extended with calendarEventId and eventTitle for event-linked reflections
  - EntryCard meeting badge for calendar-linked entries in the feed
  - Notification initialization with deep-link tap handler via GoRouter /today?eventId=
  - App lifecycle observer invalidating calendar providers on resume for pull-based catch-up
  - Reflection reminders toggle in Settings (SharedPreferences-backed)
  - Notification scheduling provider for automatic post-event nudges
affects: [04-ai-follow-up-questioning]

# Tech tracking
tech-stack:
  added: []
  patterns: [notification deep-linking via GoRouter query params, UncontrolledProviderScope for out-of-widget-tree provider access, WidgetsBindingObserver for lifecycle-based data refresh, AnimatedSize for collapsible sections, Dismissible for swipe-to-skip]

key-files:
  created:
    - lib/features/calendar/presentation/agenda_section.dart
    - lib/features/calendar/presentation/event_card.dart
  modified:
    - lib/features/today/today_screen.dart
    - lib/features/today/presentation/compose_sheet.dart
    - lib/features/today/presentation/entry_card.dart
    - lib/main.dart
    - lib/app.dart
    - lib/core/router/app_router.dart
    - lib/features/settings/settings_screen.dart
    - lib/features/calendar/presentation/calendar_providers.dart
    - lib/features/auth/data/auth_repository.dart
    - android/app/build.gradle.kts

key-decisions:
  - "UncontrolledProviderScope with explicit ProviderContainer for notification tap handler access to GoRouter outside widget tree"
  - "AgendaSection starts expanded by default per user decision -- collapsible via chevron toggle"
  - "EventCard uses left border color accent per status (blue=in_progress, orange=ended, green=reflected, grey=skipped/upcoming)"
  - "Core library desugaring enabled in Android build.gradle.kts for flutter_local_notifications java.time API compatibility"
  - "Silent Google sign-in exception caught gracefully to prevent consent dialog popup on Today tab calendar sync"

patterns-established:
  - "Deep linking pattern: notification payload -> GoRouter query parameter -> widget constructor parameter -> highlight behavior"
  - "Lifecycle catch-up pattern: WidgetsBindingObserver.didChangeAppLifecycleState(resumed) -> invalidate providers -> fresh data fetch"
  - "Event-entry linking pattern: ComposeSheet receives calendarEventId -> createEntry passes it -> updateEventStatus marks reflected with linkedEntryId"

requirements-completed: [INTG-01, INTG-02, INTG-04]

# Metrics
duration: ~30min (multi-session with checkpoint)
completed: 2026-03-04
---

# Phase 3 Plan 02: Calendar UI and Nudge Flow Summary

**Collapsible agenda section on daily canvas with event cards, compose sheet event linking, notification deep linking via GoRouter, lifecycle-based catch-up sync, and Settings reflection reminders toggle**

## Performance

- **Duration:** ~30 min (multi-session with human-verify checkpoint)
- **Started:** 2026-03-04
- **Completed:** 2026-03-04
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 12 (2 created, 10 modified)

## Accomplishments
- Complete calendar agenda UI on TodayScreen with collapsible section showing today's events and date-grouped missed events from past days
- Event cards with full status lifecycle (upcoming/in_progress/ended/reflected/skipped), swipe-to-skip, and compose sheet integration for reflections
- Notification deep linking: tap notification -> GoRouter navigates to /today?eventId=X -> event card highlighted in agenda
- App lifecycle observer triggers fresh calendar sync on resume for pull-based catch-up (INTG-04)
- Reflection reminders toggle in Settings persisted via SharedPreferences, controls notification scheduling

## Task Commits

Each task was committed atomically:

1. **Task 1: Agenda section UI, event cards, compose sheet extension, and entry card meeting badge** - `fd139d0` (feat)
2. **Task 2: Notification wiring, deep linking, app lifecycle catch-up, and Settings toggle** - `679a098` (feat)
3. **Task 3: Verify complete calendar integration end-to-end** - Human-verify checkpoint (approved by user)

Additional fix commits during execution:
- `9ff7136` - fix(android): enable core library desugaring for flutter_local_notifications
- `d3eddad` - fix(auth): catch GoogleSignInException during silent sign-in attempt
- `0f51542` - fix(calendar): prevent unwanted consent dialog on Today tab

## Files Created/Modified
- `lib/features/calendar/presentation/agenda_section.dart` - Collapsible agenda widget with today's events and date-grouped missed events (390 lines)
- `lib/features/calendar/presentation/event_card.dart` - Individual event card with status indicators, swipe-to-skip, and tap actions (236 lines)
- `lib/features/today/today_screen.dart` - Restructured with AgendaSection above entries feed, accepts highlightEventId
- `lib/features/today/presentation/compose_sheet.dart` - Extended with calendarEventId/eventTitle params, event linking on save
- `lib/features/today/presentation/entry_card.dart` - Added meeting badge for calendar-linked entries
- `lib/main.dart` - UncontrolledProviderScope, notification init with deep-link tap handler, timezone init
- `lib/app.dart` - ConsumerStatefulWidget with WidgetsBindingObserver for lifecycle catch-up
- `lib/core/router/app_router.dart` - /today route parses eventId query parameter for deep linking
- `lib/features/settings/settings_screen.dart` - Reflection reminders toggle with SharedPreferences
- `lib/features/calendar/presentation/calendar_providers.dart` - Notification scheduling provider and reflectionRemindersEnabledProvider
- `lib/features/auth/data/auth_repository.dart` - Silent sign-in exception handling
- `android/app/build.gradle.kts` - Core library desugaring for java.time API

## Decisions Made
- UncontrolledProviderScope with explicit ProviderContainer so notification tap handler can access GoRouter outside the widget tree
- AgendaSection starts expanded by default (user preference) with animated collapse via AnimatedSize
- EventCard uses color-coded left border accent: blue for in_progress, orange for ended, green for reflected, grey for skipped/upcoming
- Core library desugaring enabled in Android build.gradle.kts to satisfy flutter_local_notifications java.time requirements
- GoogleSignInException caught silently during calendar sync to prevent unwanted consent dialog appearing on Today tab

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Enabled core library desugaring for Android**
- **Found during:** Task 2 (after notification wiring)
- **Issue:** flutter_local_notifications uses java.time APIs requiring core library desugaring on Android
- **Fix:** Added `isCoreLibraryDesugaringEnabled = true` and desugaring dependency to android/app/build.gradle.kts
- **Files modified:** android/app/build.gradle.kts
- **Commit:** `9ff7136`

**2. [Rule 1 - Bug] Caught GoogleSignInException during silent sign-in**
- **Found during:** Post-Task 2 testing
- **Issue:** Calendar sync triggering GoogleSignInException when no cached credentials, causing unhandled error
- **Fix:** Added try-catch around silent sign-in attempt in auth_repository.dart
- **Files modified:** lib/features/auth/data/auth_repository.dart
- **Commit:** `d3eddad`

**3. [Rule 1 - Bug] Prevented unwanted consent dialog on Today tab**
- **Found during:** Post-Task 2 testing
- **Issue:** Calendar provider refresh on Today tab was triggering Google sign-in consent dialog unexpectedly
- **Fix:** Added guard to prevent interactive sign-in flow during background calendar sync
- **Files modified:** lib/features/calendar/presentation/calendar_providers.dart (and related)
- **Commit:** `0f51542`

---

**Total deviations:** 3 auto-fixed (1 blocking, 2 bug fixes)
**Impact on plan:** All fixes necessary for correct runtime behavior. No scope creep.

## Issues Encountered
- flutter_local_notifications v21 requires core library desugaring on Android -- resolved with build.gradle.kts configuration
- Silent Google sign-in could throw GoogleSignInException when no cached credentials -- resolved with exception handling
- Calendar provider refresh was inadvertently triggering interactive sign-in consent -- resolved with guard condition

## User Setup Required
None - all infrastructure configured in prior phases. Google Calendar OAuth was set up in Phase 1 Plan 04.

## Next Phase Readiness
- Phase 3 is fully complete: data infrastructure (Plan 01) + UI/notification flow (Plan 02)
- Calendar events appear on daily canvas, notifications fire after events end, deep linking works, catch-up surfaces missed events
- Ready for Phase 4 (AI Follow-Up Questioning) which will add AI-driven specificity drilling to entries (including calendar-linked reflections)
- No blockers for Phase 4

## Self-Check: PASSED

All 12 key files verified on disk. All 5 commits (fd139d0, 679a098, 9ff7136, d3eddad, 0f51542) verified in git log.

---
*Phase: 03-calendar-integration-and-push-notifications*
*Completed: 2026-03-04*
