---
phase: 03-calendar-integration-and-push-notifications
plan: "01"
subsystem: calendar, notifications
tags: [google-calendar-api, convex, flutter-local-notifications, timezone, shared-preferences, riverpod]

# Dependency graph
requires:
  - phase: 01-foundation-and-auth
    provides: Google OAuth, Convex backend, ConvexHttpService, auth providers
  - phase: 02-daily-canvas
    provides: Entry model, EntryRepository, entry_providers
provides:
  - Convex calendarEvents table with upsert/query/update functions
  - CalendarEvent domain model with Google Calendar and Convex JSON parsing
  - CalendarRepository for Google Calendar REST API access
  - CalendarEventRepository for Convex CRUD bridge
  - Riverpod providers for calendar sync and unreflected events
  - NotificationService for timezone-aware local push notifications
  - Entry model extended with optional calendarEventId for event-entry linking
affects: [03-02-calendar-ui-and-nudge-flow]

# Tech tracking
tech-stack:
  added: [flutter_local_notifications ^21.0.0-dev.2, timezone ^0.11.0, shared_preferences ^2.5.4]
  patterns: [Google Calendar REST API with Bearer token, calendar event upsert with status preservation, notification scheduling with TZDateTime]

key-files:
  created:
    - convex/calendarEvents.ts (backend)
    - lib/features/calendar/domain/calendar_event.dart
    - lib/features/calendar/data/calendar_repository.dart
    - lib/features/calendar/data/calendar_event_repository.dart
    - lib/features/calendar/presentation/calendar_providers.dart
    - lib/features/notifications/notification_service.dart
  modified:
    - convex/schema.ts (backend)
    - convex/entries.ts (backend)
    - lib/features/today/domain/entry.dart
    - lib/features/today/data/entry_repository.dart
    - android/app/src/main/AndroidManifest.xml
    - pubspec.yaml

key-decisions:
  - "flutter_local_notifications v21 uses all-named-parameter API (breaking change from v17+) -- adapted all calls accordingly"
  - "Convex backend not in git repo -- changes deployed to cloud; TypeScript source lives at C:/Users/micah/OneDrive/Desktop/intern_vault/back_end/"
  - "accessToken from GoogleSignInClientAuthorization is non-nullable String in google_sign_in v7 -- removed unnecessary null checks"

patterns-established:
  - "CalendarEvent.fromGoogleJson handles both timed and all-day events via start.dateTime vs start.date detection"
  - "Calendar sync pattern: fetch from Google API -> upsert into Convex (preserving user-decided statuses) -> query Convex as source of truth"
  - "NotificationService uses static class pattern with calendarEventId.hashCode & 0x7FFFFFFF for notification IDs"

requirements-completed: [INTG-01, INTG-02, INTG-04]

# Metrics
duration: 12min
completed: 2026-03-04
---

# Phase 3 Plan 01: Calendar Data Infrastructure Summary

**Convex calendarEvents table with upsert/query functions, Flutter CalendarEvent model and repositories, Google Calendar API sync via Riverpod providers, and timezone-aware local notification scheduling service**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-04T23:25:46Z
- **Completed:** 2026-03-04T23:37:46Z
- **Tasks:** 2
- **Files modified:** 17 (6 created, 11 modified)

## Accomplishments
- Convex calendarEvents table deployed with three indexes (by_user, by_user_google_id, by_user_status) and four CRUD functions
- Complete Flutter data pipeline: CalendarEvent model, CalendarRepository (Google API), CalendarEventRepository (Convex), and Riverpod sync providers
- NotificationService with timezone-aware scheduling for post-event reflection nudges
- Entry model extended with calendarEventId for event-entry linking
- AndroidManifest configured with notification permissions and boot receivers

## Task Commits

Each task was committed atomically:

1. **Task 1: Convex backend -- calendarEvents table, CRUD functions, and entries schema extension** - Deployed to Convex cloud (backend directory not in git repo)
2. **Task 2: Flutter data layer -- CalendarEvent model, repositories, providers, NotificationService, and package installation** - `b9c1392` (feat)

## Files Created/Modified
- `convex/schema.ts` (backend) - Added calendarEvents table definition and entries calendarEventId field
- `convex/calendarEvents.ts` (backend) - Four Convex functions: upsertEvent, getTodayEvents, getUnreflectedEvents, updateEventStatus
- `convex/entries.ts` (backend) - Extended createEntry mutation with optional calendarEventId
- `lib/features/calendar/domain/calendar_event.dart` - CalendarEvent model with fromJson and fromGoogleJson factories
- `lib/features/calendar/data/calendar_repository.dart` - Google Calendar REST API calls with 401 retry
- `lib/features/calendar/data/calendar_event_repository.dart` - Convex CRUD bridge for calendarEvents
- `lib/features/calendar/presentation/calendar_providers.dart` - todayCalendarEventsProvider and unreflectedEventsProvider
- `lib/features/notifications/notification_service.dart` - Local notification scheduling with timezone support
- `lib/features/today/domain/entry.dart` - Added calendarEventId field and isCalendarReflection getter
- `lib/features/today/data/entry_repository.dart` - Extended createEntry with optional calendarEventId
- `android/app/src/main/AndroidManifest.xml` - Added notification permissions and boot receivers
- `pubspec.yaml` - Added flutter_local_notifications, timezone, shared_preferences

## Decisions Made
- flutter_local_notifications v21 uses all-named-parameter API (breaking change from v17+) -- adapted initialize(), zonedSchedule(), and cancel() calls to use named params
- Convex backend directory (C:/Users/micah/OneDrive/Desktop/intern_vault/back_end/) is not tracked in the mobile_app git repo -- changes deployed directly to Convex cloud
- GoogleSignInClientAuthorization.accessToken is non-nullable String in google_sign_in v7 -- removed defensive null checks that caused dart analyze warnings

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed flutter_local_notifications v21 named parameter API**
- **Found during:** Task 2 (NotificationService implementation)
- **Issue:** Plan specified positional parameters for initialize(), zonedSchedule(), and cancel() which is the v17 API. Version 21.0.0-dev.2 uses all named parameters.
- **Fix:** Changed all three method calls to use named parameters: `settings:` for initialize, `id:/scheduledDate:/notificationDetails:` for zonedSchedule, `id:` for cancel
- **Files modified:** lib/features/notifications/notification_service.dart
- **Verification:** dart analyze passes with zero errors
- **Committed in:** b9c1392 (Task 2 commit)

**2. [Rule 1 - Bug] Removed unnecessary null checks on non-nullable accessToken**
- **Found during:** Task 2 (calendar_providers implementation)
- **Issue:** accessToken is `final String` (non-nullable) in google_sign_in v7's GoogleSignInClientAuthorization, but code had `if (token == null)` checks causing analyzer warnings
- **Fix:** Removed null checks, used `??=` operator for authorization variable
- **Files modified:** lib/features/calendar/presentation/calendar_providers.dart
- **Verification:** dart analyze passes with zero warnings
- **Committed in:** b9c1392 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bug fixes)
**Impact on plan:** Both fixes necessary for correctness with actual package versions. No scope creep.

## Issues Encountered
None -- plan executed smoothly after auto-fixing API compatibility issues.

## User Setup Required
None - no external service configuration required. Google Calendar OAuth was already configured in Phase 1 Plan 04.

## Next Phase Readiness
- Complete data infrastructure ready for Plan 02 to build calendar UI and nudge flow
- All providers, repositories, and notification service available for consumption
- Convex backend deployed and ready for queries
- No blockers for Plan 02

## Self-Check: PASSED

All 8 key files verified on disk. Commit b9c1392 verified in git log. Convex deployment verified with zero typecheck errors. dart analyze passes with zero issues.

---
*Phase: 03-calendar-integration-and-push-notifications*
*Completed: 2026-03-04*
