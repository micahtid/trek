---
phase: 03-calendar-integration-and-push-notifications
verified: 2026-03-04T00:00:00Z
status: human_needed
score: 9/9 automated truths verified
re_verification: false
human_verification:
  - test: "Calendar events appear on Today tab daily canvas"
    expected: "When Google Calendar is connected in Settings, today's meetings display in a collapsible 'Today's Meetings' section above the entries feed, sorted by start time"
    why_human: "Requires a live device with Google Calendar OAuth granted and actual calendar events to observe rendering"
  - test: "Event card status indicators display correctly"
    expected: "Upcoming events show clock icon; in-progress events show filled blue dot; ended events show orange 'Needs reflection' badge with X button; reflected events show green checkmark with preview text; skipped events appear greyed out"
    why_human: "Status rendering depends on real event timing and lifecycle state"
  - test: "Tapping ended event card opens ComposeSheet pre-filled with event context"
    expected: "Bottom sheet opens with event title shown at top (calendar icon + title), hint text reads 'How did [EventName] go?'"
    why_human: "UI interaction and visual presentation require device testing"
  - test: "Saving reflection updates event card to reflected state"
    expected: "After typing text and tapping Save, the compose sheet closes, the event card shows green checkmark with 1-line text preview, and the saved entry appears in the feed below with a 'Meeting' badge chip"
    why_human: "Full round-trip: entry create -> updateEventStatus -> provider invalidate -> UI rebuild"
  - test: "Swipe-to-skip or X button marks event skipped"
    expected: "Swiping an event card left reveals 'Skip' label; releasing dismisses it and the card reappears greyed out with 50% opacity. Tapping the X on an ended event does the same."
    why_human: "Dismissible gesture interaction requires device testing"
  - test: "Push notification fires 5 minutes after a calendar event ends"
    expected: "Approximately 5 minutes after an event's end time, a system notification appears: title 'How did it go?', body 'Hey, how did [EventName] go?'"
    why_human: "Requires real-time waiting and notification system; cannot verify programmatically"
  - test: "Notification tap deep-links to the highlighted event on Today tab"
    expected: "Tapping the notification opens the app and navigates to /today?eventId=X; the relevant event card has an amber background highlight"
    why_human: "Requires device, active notification, and GoRouter navigation observation"
  - test: "App resume triggers catch-up: missed events appear with date headers"
    expected: "After closing the app for a period with un-reflected events, reopening shows those events under date-grouped headers (e.g., 'Monday, March 2') with orange labels"
    why_human: "Requires multi-session testing across app restarts"
  - test: "Reflection reminders toggle in Settings works"
    expected: "Settings screen has a 'Notifications' section with a 'Reflection reminders' switch. Toggling off cancels all pending notifications; toggling on re-triggers scheduling."
    why_human: "Notification cancellation and rescheduling behavior requires device observation"
---

# Phase 3: Calendar Integration and Push Notifications — Verification Report

**Phase Goal:** Sync Google Calendar events, display agenda on daily canvas, send push notification nudges after meetings, deep link to compose reflections
**Verified:** 2026-03-04
**Status:** human_needed — all automated checks PASSED; 9 items require device/human testing
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CalendarEvent model parses Google Calendar API JSON for both timed and all-day events | VERIFIED | `fromGoogleJson` detects `start.containsKey('date')` for all-day vs `dateTime` for timed; 142 lines, fully substantive |
| 2 | CalendarRepository fetches today's events and events-since-date from Google Calendar API using Bearer token | VERIFIED | `_baseUrl` = googleapis.com/calendar/v3, `Authorization: Bearer $accessToken` header, `fetchTodayEvents` and `fetchEventsSince` both implemented; throws `CalendarAuthExpiredException` on 401 |
| 3 | CalendarEventRepository can upsert, query, and update status of calendar events in Convex | VERIFIED | All four Convex path calls present: `calendarEvents:upsertEvent`, `calendarEvents:getTodayEvents`, `calendarEvents:getUnreflectedEvents`, `calendarEvents:updateEventStatus`; 111 lines |
| 4 | NotificationService schedules timezone-aware local notifications and handles tap callbacks | VERIFIED | `tz.TZDateTime.from(scheduledTime, tz.local)` used in `zonedSchedule`; `onDidReceiveNotificationResponse: onTap` wired in `initialize`; `cancelAll` and `cancelForEvent` implemented; 121 lines |
| 5 | Entry model supports optional calendarEventId for event-entry linking | VERIFIED | `final String? calendarEventId` field present; parsed in `fromJson`; `isCalendarReflection` getter returns `calendarEventId != null` |
| 6 | Convex calendarEvents table exists with userId+googleEventId dedup index | VERIFIED | `schema.ts` defines calendarEvents table with `.index("by_user_google_id", ["userId", "googleEventId"])` and two additional indexes; `calendarEvents.ts` has all four functions deployed |
| 7 | User sees today's Google Calendar meetings in collapsible agenda section on daily canvas | VERIFIED (automated) | `AgendaSection` in `today_screen.dart` at position above entries feed; watches `todayCalendarEventsProvider` and `unreflectedEventsProvider`; starts expanded; AnimatedSize collapse; 390 lines |
| 8 | Notification tap deep-links to relevant event via GoRouter | VERIFIED (automated) | `main.dart` tap handler: `container.read(routerProvider).go('/today?eventId=$calendarEventId')`; `app_router.dart` parses `state.uri.queryParameters['eventId']` and passes to `TodayScreen(highlightEventId: eventId)` |
| 9 | App lifecycle triggers fresh calendar sync and catch-up check on resume | VERIFIED (automated) | `app.dart` implements `WidgetsBindingObserver`, `didChangeAppLifecycleState` invalidates `todayCalendarEventsProvider` and `unreflectedEventsProvider` on `AppLifecycleState.resumed`; updates `lastOpenTime` in SharedPreferences |

**Score:** 9/9 truths verified (automated)

---

### Required Artifacts

#### Plan 01 Artifacts

| Artifact | Min Lines | Actual Lines | Exists | Substantive | Wired | Status |
|----------|-----------|--------------|--------|-------------|-------|--------|
| `convex/schema.ts` (backend) | — | 56 | YES | YES — calendarEvents table + 3 indexes, entries.calendarEventId | N/A (backend) | VERIFIED |
| `convex/calendarEvents.ts` (backend) | — | 134 | YES | YES — upsertEvent, getTodayEvents, getUnreflectedEvents, updateEventStatus | N/A (backend) | VERIFIED |
| `convex/entries.ts` (backend) | — | 125 | YES | YES — createEntry accepts optional calendarEventId | N/A (backend) | VERIFIED |
| `lib/features/calendar/domain/calendar_event.dart` | 40 | 142 | YES | YES — fromJson, fromGoogleJson, getters, ==, hashCode | Imported by calendar_repository, calendar_event_repository, agenda_section, event_card | VERIFIED |
| `lib/features/calendar/data/calendar_repository.dart` | 50 | 117 | YES | YES — fetchTodayEvents, fetchEventsSince, exceptions, Bearer auth | Consumed by calendar_providers.dart | VERIFIED |
| `lib/features/calendar/data/calendar_event_repository.dart` | 40 | 111 | YES | YES — all 4 Convex CRUD calls | Consumed by calendar_providers.dart, agenda_section, compose_sheet | VERIFIED |
| `lib/features/calendar/presentation/calendar_providers.dart` | 30 | 210 | YES | YES — todayCalendarEventsProvider, unreflectedEventsProvider, calendarNotificationSchedulerProvider, reflectionRemindersEnabledProvider | Watched by agenda_section; used by app.dart, settings_screen | VERIFIED |
| `lib/features/notifications/notification_service.dart` | 50 | 121 | YES | YES — initialize, scheduleReflectionNudge, cancelAll, cancelForEvent | Called from main.dart, calendar_providers, settings_screen | VERIFIED |

#### Plan 02 Artifacts

| Artifact | Min Lines | Actual Lines | Exists | Substantive | Wired | Status |
|----------|-----------|--------------|--------|-------------|-------|--------|
| `lib/features/calendar/presentation/agenda_section.dart` | 80 | 390 | YES | YES — collapsible, today events, date-grouped missed events, highlight support | Imported and used in today_screen.dart | VERIFIED |
| `lib/features/calendar/presentation/event_card.dart` | 60 | 236 | YES | YES — all 5 status variants, swipe Dismissible, skip X button, tap routing | Used in agenda_section.dart | VERIFIED |
| `lib/features/today/today_screen.dart` | — | 163 | YES | YES — AgendaSection at top, Expanded entries feed, highlightEventId param | Rendered by app_router.dart GoRoute /today | VERIFIED |
| `lib/features/today/presentation/compose_sheet.dart` | — | 296 | YES | YES — calendarEventId, eventTitle params, event label display, hint text override, updateEventStatus on save | Opened by agenda_section; embedded in app_shell FAB | VERIFIED |
| `lib/main.dart` | — | 49 | YES | YES — UncontrolledProviderScope, NotificationService.initialize with tap handler, getNotificationAppLaunchDetails, initialEventId | App entry point | VERIFIED |
| `lib/core/router/app_router.dart` | — | 107 | YES | YES — /today route parses `state.uri.queryParameters['eventId']`, passes to TodayScreen | Used by App, main.dart tap handler | VERIFIED |

---

### Key Link Verification

#### Plan 01 Key Links

| From | To | Via | Pattern | Status |
|------|----|-----|---------|--------|
| `calendar_repository.dart` | Google Calendar REST API | http GET with Bearer token | `googleapis.com/calendar` at line 38 | WIRED |
| `calendar_event_repository.dart` | ConvexHttpService | mutation/query calls | `calendarEvents:` at lines 25, 46, 70, 101 | WIRED |
| `calendar_providers.dart` | calendar_repository + calendar_event_repository | Riverpod FutureProvider orchestrating sync | `calendarRepositoryProvider` (line 63), `calendarEventRepositoryProvider` (line 64, 133) | WIRED |

#### Plan 02 Key Links

| From | To | Via | Pattern | Status |
|------|----|-----|---------|--------|
| `event_card.dart` → `agenda_section.dart` | ComposeSheet | onTap opens ComposeSheet with calendarEventId + eventTitle | `calendarEventId: event.id` (line 53), `eventTitle: event.title` (line 54) in agenda_section.dart | WIRED |
| `compose_sheet.dart` | CalendarEventRepository.updateEventStatus | After save, updates event status to reflected with linkedEntryId | `updateEventStatus` called at line 142 of compose_sheet.dart | WIRED |
| `main.dart` | GoRouter /today?eventId= | Notification tap handler calls router.go | `container.read(routerProvider).go('/today?eventId=$calendarEventId')` at line 27 | WIRED |
| `agenda_section.dart` | todayCalendarEventsProvider + unreflectedEventsProvider | ConsumerWidget watching both providers | `ref.watch(todayCalendarEventsProvider)` (line 102), `ref.watch(unreflectedEventsProvider)` (line 103) | WIRED |

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| **INTG-01** | 03-01, 03-02 | User sees Google Calendar meetings auto-populated on their daily canvas | SATISFIED | `todayCalendarEventsProvider` fetches from Google Calendar API, upserts to Convex, returns events; `AgendaSection` renders them in TodayScreen above entries feed |
| **INTG-02** | 03-01, 03-02 | User receives push notification after Calendar event ends asking for reflection; tapping deep-links to the event | SATISFIED | `NotificationService.scheduleReflectionNudge` fires 5 min after `eventEndTime`; payload = calendarEventId; `main.dart` tap handler navigates to `/today?eventId=X`; `AgendaSection` highlights the event |
| **INTG-04** | 03-01, 03-02 | App checks for missed Calendar events on open and surfaces reflection prompts (pull-based catch-up) | SATISFIED | `unreflectedEventsProvider` reads `lastOpenTime` from SharedPreferences and queries Convex for unreflected events since that timestamp; `AgendaSection` shows date-grouped missed events; `app.dart` lifecycle observer refreshes providers on resume |

All three Phase 3 requirements (INTG-01, INTG-02, INTG-04) are addressed by the implemented code. No orphaned requirements were found — REQUIREMENTS.md maps exactly these three IDs to Phase 3.

---

### Anti-Patterns Found

| File | Pattern | Assessment | Impact |
|------|---------|------------|--------|
| `calendar_event_repository.dart:59,83` | `return []` | Legitimate: defensive fallback when Convex returns non-List (type guard, not stub) | None |
| `calendar_providers.dart:61,112,131,156` | `return []` | Legitimate: early-exit when userId is null or Calendar scope not granted; documented in comments | None |
| `agenda_section.dart:339` | `return null` | Legitimate: returns null reflection preview for non-reflected events | None |

No genuine stubs, TODOs, FIXMEs, or placeholder implementations found across all phase files. The `return []` and `return null` patterns are all guarded early-exits with proper conditions, not empty implementations.

---

### Human Verification Required

The following items cannot be verified programmatically and require device testing:

#### 1. Calendar Events Render on Today Tab

**Test:** On an Android device with Google Calendar connected in Settings, open the Today tab.
**Expected:** A "Today's Meetings" collapsible section appears above the entries feed showing today's calendar events with time ranges and titles. If no events exist for today, the section is invisible.
**Why human:** Requires live Google Calendar OAuth, real event data, and visual rendering observation.

#### 2. Event Card Status Indicators

**Test:** Observe event cards at different times of day (before, during, after events).
**Expected:** Upcoming events show a clock icon; in-progress events show a filled blue dot; ended events show an orange "Needs reflection" container badge with an X button; reflected events show a green checkmark with 1-line preview text; skipped events appear at 50% opacity.
**Why human:** Status depends on real event timing and the runtime status lifecycle.

#### 3. ComposeSheet Opens with Event Context

**Test:** Tap an event card with "Needs reflection" status (orange badge).
**Expected:** Bottom sheet opens with a calendar icon row showing the event title, and the text field hint reads "How did [EventName] go?".
**Why human:** UI interaction and hint text rendering require device testing.

#### 4. Reflection Saves and Updates Event + Feed

**Test:** Type a reflection in the compose sheet and tap Save.
**Expected:** Sheet closes, the event card updates to show a green checkmark with the first line of your text, and the entry appears in the feed below with a primary-colored "Meeting" chip badge.
**Why human:** Full round-trip covers createEntry + updateEventStatus + provider invalidation + UI rebuild; requires live backend.

#### 5. Swipe-to-Skip Gesture

**Test:** Swipe an event card to the left (endToStart).
**Expected:** An orange "Skip" background label slides into view; releasing the card marks it skipped (greyed out at 50% opacity). The X button on ended event cards provides the same result via tap.
**Why human:** Dismissible gesture behavior requires physical device interaction.

#### 6. Push Notification Fires After Event Ends

**Test:** With an upcoming calendar event and notifications enabled, wait approximately 5 minutes after the event's scheduled end time.
**Expected:** A system notification appears with title "How did it go?" and body "Hey, how did [EventName] go?".
**Why human:** Requires real-time waiting; `zonedSchedule` uses `exactAllowWhileIdle` which needs a real device.

#### 7. Notification Tap Deep-Links to Event

**Test:** Tap the notification received in test 6.
**Expected:** The app opens (or comes to foreground) and navigates to the Today screen. The event card that triggered the notification has an amber background highlight.
**Why human:** Requires notification, GoRouter navigation, and amber highlight rendering to be observed end-to-end.

#### 8. App Resume Surfaces Missed Events

**Test:** Close the app entirely, wait until after a calendar event has ended without reflecting, then reopen the app.
**Expected:** The "Today's Meetings" section (or a section for past dates) shows the missed event under a date-labeled header (e.g., "Wednesday, March 4") with the orange "Needs reflection" badge.
**Why human:** Requires multi-session testing; `lastOpenTime` SharedPreferences tracking must persist across app kills.

#### 9. Reflection Reminders Toggle in Settings

**Test:** Navigate to Settings > Notifications. Toggle "Reflection reminders" off, then back on.
**Expected:** Toggle persists across Settings visits. Toggling off should cancel any pending notifications (observable via system notification tray). Toggling on should re-enable scheduling for upcoming events.
**Why human:** Notification cancellation and pending notification state cannot be verified programmatically.

---

### Automated Verification Summary

All automated checks passed. The phase delivered:

- Complete Convex backend: `calendarEvents` table with 3 indexes, 4 CRUD functions, and `entries.calendarEventId` extension
- Complete Flutter data layer: `CalendarEvent` model (fromJson + fromGoogleJson), `CalendarRepository` (Google Calendar REST API), `CalendarEventRepository` (Convex CRUD bridge), and Riverpod providers orchestrating the full sync pipeline
- Full UI layer: `AgendaSection` (390 lines, collapsible, date-grouped missed events), `EventCard` (236 lines, all 5 status variants, swipe-to-skip), `ComposeSheet` extended with event linking, `EntryCard` with meeting badge
- Notification infrastructure: `NotificationService` with timezone-aware scheduling, Android manifest permissions and receivers, `pubspec.yaml` packages installed
- Deep-link wiring: `main.dart` → GoRouter `/today?eventId=` → `TodayScreen.highlightEventId` → `AgendaSection` amber highlight
- Lifecycle catch-up: `app.dart` `WidgetsBindingObserver` invalidates providers on `AppLifecycleState.resumed`
- Settings toggle: `reflectionRemindersEnabledProvider` + `SwitchListTile` in `SettingsScreen` + `NotificationService.cancelAll()` on disable

No stub implementations, TODO comments, or broken key links were found.

---

_Verified: 2026-03-04_
_Verifier: Claude (gsd-verifier)_
