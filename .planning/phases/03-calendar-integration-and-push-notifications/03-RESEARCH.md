# Phase 3: Calendar Integration and Push Notifications - Research

**Researched:** 2026-03-04
**Domain:** Google Calendar API, Local Push Notifications, Deep Linking, Convex Backend Sync
**Confidence:** HIGH

## Summary

Phase 3 requires three interlocking systems: (1) fetching Google Calendar events and displaying them on the daily canvas, (2) scheduling local push notifications 5 minutes after calendar events end, and (3) deep-linking from notification taps to the relevant event on the canvas with pull-based catch-up for missed events.

The architecture calls the Google Calendar API directly from the Flutter client using the access token obtained via `google_sign_in` v7's `authorizeScopes()` -- the same mechanism already wired in `CalendarAuthSection`. Calendar events are stored in a new Convex `calendarEvents` table for persistence, status tracking (upcoming/in-progress/ended/reflected/skipped), and linking to entries. Local notifications (via `flutter_local_notifications`) replace FCM entirely -- since notifications are time-based relative to calendar events the client already knows about, there is no need for Firebase Cloud Messaging, a Firebase project, or server-sent push notifications. This eliminates the entire FCM dependency chain (`firebase_core`, `firebase_messaging`, APNs certificates, `google-services.json`).

**Primary recommendation:** Use client-side Google Calendar API calls with `http` package + Bearer token, store events in Convex `calendarEvents` table, and schedule local notifications via `flutter_local_notifications` zonedSchedule. No Firebase dependencies needed.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Dedicated agenda section at the top of the daily canvas, manual entries feed below
- Each event card shows: time, title, and status indicator (upcoming, in progress, ended/needs reflection, reflected, skipped)
- Tapping an event card opens the existing compose bottom sheet pre-linked to that event
- Agenda section is collapsible -- starts expanded, user can minimize to focus on entries
- Compose sheet shows event title at top with a guiding question as placeholder text (e.g., "How did Sprint Planning go?")
- One reflection per event -- 1:1 mapping between calendar event and entry
- After reflecting, event card updates to show green checkmark + 1-line preview of the reflection text; tapping opens the linked entry in detail view
- Linked entry appears in both places: the entries feed below (with a meeting badge on the card) and accessible from the event card in the agenda
- Push notification fires 5 minutes after a calendar event ends
- Casual coach tone -- friendly and encouraging (e.g., "Hey, how did Sprint Planning go?")
- No frequency cap -- every calendar event gets its own notification
- "Reflection reminders" toggle in Settings to disable push notifications while keeping calendar sync active
- Tapping a notification deep-links directly to the relevant event/entry on the daily canvas
- On app open, check for un-reflected events since user's last app open (not limited to today -- catches weekend gaps)
- Missed events surface inline in the agenda section with an orange "Needs reflection" badge -- no extra banners or overlays
- When missed events span multiple days, group by date with date-labeled section headers (consistent with search results pattern from Phase 2)
- Users can dismiss an event without reflecting -- swipe or tap X changes status to "skipped"

### Claude's Discretion
- Exact notification copy variations (beyond the established casual coach tone)
- Loading states while calendar events sync
- Error handling for Calendar API failures or token expiry
- How the collapsible agenda animates (expand/collapse transition)
- Event card visual design details (colors, icons, spacing)
- How "skipped" events display differently from "needs reflection"

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INTG-01 | User sees Google Calendar meetings auto-populated on their daily canvas | Google Calendar REST API events.list with Bearer token from google_sign_in v7; CalendarEvent model stored in Convex; agenda section widget with collapsible UI |
| INTG-02 | User receives push notification after a Calendar event ends asking for reflection | flutter_local_notifications zonedSchedule at event.endTime + 5 minutes; no Firebase needed; notification payload carries calendarEventId for deep linking |
| INTG-04 | App checks for missed Calendar events on open and surfaces reflection prompts (pull-based catch-up) | On app resume, query Convex for calendarEvents where status != "reflected" and status != "skipped" since lastOpenTime; surface inline in agenda with orange badge and date-grouped section headers |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| google_sign_in | ^7.2.0 | Already installed; provides access tokens via authorizeScopes for Calendar API | Project already uses this for Google auth; v7 has authorizationClient API |
| http | ^1.6.0 | Already installed; direct REST calls to Google Calendar API | Simpler than adding googleapis + extension packages; consistent with existing ConvexHttpService pattern |
| flutter_local_notifications | ^20.1.0 | Schedule and display local push notifications | No Firebase dependency; full timezone-aware scheduling; deep link via payload |
| timezone | ^0.10.0 | TZDateTime for zonedSchedule scheduling | Required dependency for flutter_local_notifications scheduled notifications |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| shared_preferences | ^2.3.0 | Store lastOpenTime for pull-based catch-up, reflection reminders toggle | Lightweight key-value storage for app-level preferences |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct HTTP Calendar API calls | googleapis + extension_google_sign_in_as_googleapis_auth | googleapis (v16.0.0) adds ~80 Google API wrappers; extension package (v3.0.0) adds another layer; project already has a working HTTP pattern with ConvexHttpService; direct REST is simpler and consistent |
| flutter_local_notifications | firebase_messaging (FCM) | FCM requires firebase_core, Firebase project setup, google-services.json, APNs certs for iOS, and a server to trigger notifications; since our notifications are time-based off local calendar data, local notifications are a perfect fit with zero server infrastructure |
| shared_preferences | flutter_secure_storage (already installed) | Secure storage is for secrets; lastOpenTime and toggle state are not sensitive |

**Installation:**
```bash
flutter pub add flutter_local_notifications timezone shared_preferences
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
  features/
    calendar/
      data/
        calendar_repository.dart      # Google Calendar REST API calls
        calendar_event_repository.dart # Convex CRUD for calendarEvents table
      domain/
        calendar_event.dart           # CalendarEvent model (maps to Convex doc)
      presentation/
        calendar_providers.dart       # Riverpod providers for events, sync state
        agenda_section.dart           # Collapsible agenda widget
        event_card.dart               # Individual event card widget
    today/
      presentation/
        compose_sheet.dart            # Extended with optional calendarEventId
    notifications/
      notification_service.dart       # flutter_local_notifications setup + scheduling
```

### Pattern 1: Client-Side Calendar Sync
**What:** Flutter app calls Google Calendar API directly using access token from google_sign_in, then upserts events into Convex calendarEvents table.
**When to use:** On app open and on manual pull-to-refresh.
**Why client-side:** The access token lives on the client (google_sign_in manages it); sending it to Convex backend to make the call adds complexity and token-management burden without benefit. Read-only calendar access is a simple GET request.

```dart
// calendar_repository.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarRepository {
  /// Fetches today's calendar events from Google Calendar API.
  /// Access token from google_sign_in v7 authorizeScopes().
  Future<List<RawCalendarEvent>> fetchTodayEvents(String accessToken) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final uri = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events'
    ).replace(queryParameters: {
      'timeMin': startOfDay.toUtc().toIso8601String(),
      'timeMax': endOfDay.toUtc().toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'fields': 'items(id,summary,start,end,status)',
    });

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List? ?? [];
      return items
          .map((e) => RawCalendarEvent.fromGoogleJson(e))
          .toList();
    }

    if (response.statusCode == 401) {
      throw CalendarAuthExpiredException();
    }

    throw CalendarApiException('HTTP ${response.statusCode}');
  }

  /// Fetches events since a given date (for pull-based catch-up).
  Future<List<RawCalendarEvent>> fetchEventsSince(
    String accessToken,
    DateTime since,
  ) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events'
    ).replace(queryParameters: {
      'timeMin': since.toUtc().toIso8601String(),
      'timeMax': DateTime.now().toUtc().toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'fields': 'items(id,summary,start,end,status)',
    });

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List? ?? [];
      return items
          .map((e) => RawCalendarEvent.fromGoogleJson(e))
          .toList();
    }

    throw CalendarApiException('HTTP ${response.statusCode}');
  }
}
```

### Pattern 2: Access Token Retrieval (google_sign_in v7)
**What:** Get OAuth access token for calendar.readonly scope using the existing authorization flow.
**When to use:** Before any Calendar API call; cache and reuse until 401.

```dart
// In calendar_providers.dart or a shared auth helper
import 'package:google_sign_in/google_sign_in.dart';

Future<String> getCalendarAccessToken() async {
  const calendarScope = 'https://www.googleapis.com/auth/calendar.readonly';
  final authClient = GoogleSignIn.instance.authorizationClient;

  // Try existing authorization first (no user interaction)
  var authorization = await authClient.authorizationForScopes([calendarScope]);

  if (authorization == null) {
    // Request new authorization (shows consent dialog)
    authorization = await authClient.authorizeScopes([calendarScope]);
  }

  final token = authorization.accessToken;
  if (token == null) {
    throw StateError('Calendar access token is null after authorization');
  }
  return token;
}
```

### Pattern 3: CalendarEvent Model and Convex Storage
**What:** Store synced calendar events in Convex for persistence, status tracking, and entry linking.
**When to use:** After fetching from Google Calendar API, upsert into Convex.

```dart
// domain/calendar_event.dart
class CalendarEvent {
  final String id;              // Convex document _id
  final String userId;          // Owner
  final String googleEventId;   // Google Calendar event ID (for dedup)
  final String title;           // Event summary
  final int startTime;          // Unix ms
  final int endTime;            // Unix ms
  final String status;          // "upcoming" | "in_progress" | "ended" | "reflected" | "skipped"
  final String? linkedEntryId;  // Convex entry _id (null until reflected)
  final int creationTime;       // Convex _creationTime

  // ... constructor, fromJson, etc.
}
```

```typescript
// Convex schema addition (convex/schema.ts)
calendarEvents: defineTable({
  userId: v.string(),
  googleEventId: v.string(),
  title: v.string(),
  startTime: v.number(),   // Unix ms
  endTime: v.number(),     // Unix ms
  status: v.string(),      // "upcoming" | "in_progress" | "ended" | "reflected" | "skipped"
  linkedEntryId: v.optional(v.string()),
})
  .index("by_user", ["userId"])
  .index("by_user_google_id", ["userId", "googleEventId"])
  .index("by_user_status", ["userId", "status"])
```

### Pattern 4: Local Notification Scheduling
**What:** Schedule a local notification 5 minutes after each calendar event ends.
**When to use:** After syncing calendar events, for each event that hasn't ended yet.

```dart
// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    required void Function(NotificationResponse) onTap,
  }) async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: onTap,
    );
  }

  /// Schedule a reflection nudge 5 minutes after an event ends.
  static Future<void> scheduleReflectionNudge({
    required String calendarEventId,
    required String eventTitle,
    required DateTime eventEndTime,
  }) async {
    final scheduledTime = tz.TZDateTime.from(
      eventEndTime.add(const Duration(minutes: 5)),
      tz.local,
    );

    // Don't schedule if the time has already passed
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: calendarEventId.hashCode,  // Stable int ID from event ID
      title: 'How did it go?',
      body: 'Hey, how did $eventTitle go?',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reflection_nudges',
          'Reflection Reminders',
          channelDescription: 'Nudges to reflect after calendar events',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: calendarEventId,  // Used for deep linking on tap
    );
  }

  /// Cancel all pending notifications (e.g., when user disables reminders).
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
```

### Pattern 5: Notification Deep Linking via GoRouter
**What:** When user taps a notification, navigate to the today screen with the relevant event highlighted.
**When to use:** On notification tap callback.

```dart
// In main.dart or app initialization
void _handleNotificationTap(NotificationResponse response) {
  final calendarEventId = response.payload;
  if (calendarEventId != null && calendarEventId.isNotEmpty) {
    // Use GoRouter to navigate with query parameter
    // The routerProvider is accessible via the global ProviderContainer
    final router = _container.read(routerProvider);
    router.go('/today?eventId=$calendarEventId');
  }
}

// In app_router.dart, update /today route:
GoRoute(
  path: '/today',
  pageBuilder: (context, state) {
    final eventId = state.uri.queryParameters['eventId'];
    return NoTransitionPage(
      child: TodayScreen(highlightEventId: eventId),
    );
  },
),
```

### Pattern 6: Pull-Based Catch-Up on App Resume
**What:** On app open (or resume from background), check for un-reflected events since last open.
**When to use:** In a WidgetsBindingObserver or via Riverpod provider that watches app lifecycle.

```dart
// In a provider or widget that observes app lifecycle
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;
  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger calendar sync and catch-up check
      ref.invalidate(calendarEventsProvider);
    }
  }
}

// calendarEventsProvider fetches:
// 1. Today's events from Google Calendar API
// 2. Un-reflected events from Convex (status != "reflected" and != "skipped")
// 3. Updates lastOpenTime in SharedPreferences
```

### Pattern 7: Entry-Event Linking
**What:** When creating a reflection for a calendar event, link the entry to the event via calendarEventId.
**When to use:** In ComposeSheet when opened from an event card.

```dart
// Extended ComposeSheet accepts optional event context
class ComposeSheet extends ConsumerStatefulWidget {
  final String? calendarEventId;  // If non-null, this is a reflection for a calendar event
  final String? eventTitle;       // Pre-fill the guiding question

  const ComposeSheet({
    super.key,
    this.calendarEventId,
    this.eventTitle,
  });
}

// In _saveEntry, include calendarEventId:
await ref.read(entryRepositoryProvider).createEntry(
  userId: userId,
  body: text,
  inputMethod: _inputMethod,
  calendarEventId: widget.calendarEventId,  // NEW: link to calendar event
);

// After saving, update the calendar event status to "reflected":
if (widget.calendarEventId != null) {
  await ref.read(calendarEventRepositoryProvider).updateStatus(
    calendarEventId: widget.calendarEventId!,
    status: 'reflected',
    linkedEntryId: newEntryId,
  );
}
```

### Anti-Patterns to Avoid
- **Using FCM for time-based local notifications:** FCM is for server-to-device push. When the trigger data (event end times) is already on the client, local notifications are simpler, faster, and require zero server infrastructure.
- **Calling Calendar API from Convex backend:** The OAuth access token lives on the client (google_sign_in). Sending it to the backend to proxy the call adds latency and token management complexity for zero benefit. Read-only GET requests are perfectly fine client-side.
- **Storing access tokens in Convex:** Access tokens expire in ~1 hour and google_sign_in handles refresh. Storing them server-side creates stale-token bugs.
- **Using googleapis + extension_google_sign_in_as_googleapis_auth:** Adds two heavy packages when a single HTTP GET with Bearer token does the same thing. The project already uses the `http` package with this exact pattern in ConvexHttpService.
- **Relying solely on push notifications without pull-based catch-up:** iOS aggressively kills background processes; force-quit apps never receive FCM. Pull-based catch-up on app open is essential (already noted in STATE.md blockers).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notification scheduling | Custom timer/alarm system | flutter_local_notifications zonedSchedule | Handles timezone, DST, exact alarms, wake-from-doze, OS permissions |
| Notification permissions | Manual permission request logic | flutter_local_notifications requestPermission | Handles Android 13+ POST_NOTIFICATIONS and iOS permission dialogs |
| Timezone math | DateTime arithmetic for notification times | timezone package TZDateTime | DST transitions cause DateTime.add to be wrong by an hour |
| Calendar event deduplication | Custom diffing logic | Convex index on (userId, googleEventId) + upsert pattern | Google Calendar event IDs are stable; upsert on composite key is idempotent |
| Deep link parsing | Manual URI parsing | GoRouter query parameters | GoRouter already parses state.uri.queryParameters |

**Key insight:** The temptation is to build a "proper" push notification system with FCM + backend scheduling. But the user's calendar data is already on the client after the sync step -- scheduling a local notification is one line of code vs. an entire Firebase project setup.

## Common Pitfalls

### Pitfall 1: Access Token Expiry Mid-Session
**What goes wrong:** Calendar API returns 401 after the access token expires (~1 hour). App shows an error or empty agenda.
**Why it happens:** google_sign_in v7 does not auto-refresh access tokens (only ID tokens are refreshed). The access token from authorizeScopes/authorizationForScopes has a ~1 hour lifetime.
**How to avoid:** On 401 response from Calendar API, call `authorizationForScopes()` again to get a fresh token, then retry the request. Wrap Calendar API calls in a retry-on-401 helper.
**Warning signs:** Calendar events load on first open but show errors after the app has been open for 60+ minutes.

### Pitfall 2: Notification ID Collision
**What goes wrong:** Two calendar events get the same notification ID, and one notification silently replaces the other.
**Why it happens:** flutter_local_notifications uses an `int` ID. If you use `hashCode` of a string, collisions are possible (though rare).
**How to avoid:** Use a deterministic hash that maps Google Calendar event IDs to unique ints. Store the mapping in SharedPreferences or generate IDs from a counter persisted in Convex.
**Warning signs:** User has back-to-back meetings but only gets one notification.

### Pitfall 3: Scheduling Notifications for Past Events
**What goes wrong:** On first sync, the app tries to schedule notifications for events that already ended hours ago, triggering immediate notification spam.
**Why it happens:** Calendar API returns all events for today, including those that ended before the sync.
**How to avoid:** Before scheduling, check if `eventEndTime + 5 minutes` is in the future. Skip scheduling for past events. For past events, directly set status to "ended" and let pull-based catch-up handle them.
**Warning signs:** User opens the app at 3 PM and gets 5 notifications instantly for morning meetings.

### Pitfall 4: Android 13+ POST_NOTIFICATIONS Permission
**What goes wrong:** Notifications are scheduled but never appear on Android 13+.
**Why it happens:** Android 13 (API 33) requires runtime POST_NOTIFICATIONS permission. Without it, notifications are silently suppressed.
**How to avoid:** Request notification permission during notification service initialization. Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to AndroidManifest.xml. Use flutter_local_notifications' built-in permission request.
**Warning signs:** Notifications work on older Android devices but not on Android 13+ devices.

### Pitfall 5: Exact Alarm Permission on Android 12+
**What goes wrong:** Scheduled notifications don't fire at the exact time on Android 12+.
**Why it happens:** Android 12 introduced SCHEDULE_EXACT_ALARM permission. Without it, the OS batches alarms.
**How to avoid:** Add `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>` to AndroidManifest.xml. Use `AndroidScheduleMode.exactAllowWhileIdle` in zonedSchedule.
**Warning signs:** Notifications arrive 5-15 minutes late, batched together.

### Pitfall 6: All-Day Events Have No endTime
**What goes wrong:** All-day events from Google Calendar use `date` instead of `dateTime` in start/end fields. Parsing fails or returns null.
**Why it happens:** Google Calendar API returns `{ "start": { "date": "2026-03-04" } }` for all-day events vs `{ "start": { "dateTime": "2026-03-04T09:00:00-05:00" } }` for timed events.
**How to avoid:** Check for both `dateTime` and `date` fields when parsing. For all-day events, either skip them entirely (they are rarely meetings) or treat them differently in the UI (no reflection prompt, no notification).
**Warning signs:** App crashes when user has a birthday or holiday on their calendar.

### Pitfall 7: Duplicate Events After Re-Sync
**What goes wrong:** Calendar events appear twice in the agenda after pull-to-refresh or app restart.
**Why it happens:** Sync fetches all events for today and creates new Convex documents without checking for existing ones.
**How to avoid:** Use upsert pattern: index on (userId, googleEventId), query existing events first, only insert new ones or update changed ones. Never blindly insert.
**Warning signs:** Agenda shows "Sprint Planning" twice with identical times.

### Pitfall 8: ComposeSheet State Not Passed Through
**What goes wrong:** User taps event card, ComposeSheet opens but doesn't show the event title or link the entry to the event.
**Why it happens:** ComposeSheet was built without optional calendarEventId parameter. Opening it without the parameter creates an unlinked entry.
**How to avoid:** Add calendarEventId and eventTitle as optional constructor parameters to ComposeSheet. When opened from an event card, pass both values.
**Warning signs:** Entries created from event cards don't show the meeting badge and event cards never show "reflected" status.

## Code Examples

### Google Calendar API Response Parsing
```dart
// Source: Google Calendar API v3 events.list documentation
class RawCalendarEvent {
  final String id;
  final String summary;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;

  const RawCalendarEvent({
    required this.id,
    required this.summary,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
  });

  factory RawCalendarEvent.fromGoogleJson(Map<String, dynamic> json) {
    final start = json['start'] as Map<String, dynamic>;
    final end = json['end'] as Map<String, dynamic>;

    // All-day events use 'date', timed events use 'dateTime'
    final isAllDay = start.containsKey('date') && !start.containsKey('dateTime');

    DateTime parseGoogleTime(Map<String, dynamic> timeObj) {
      if (timeObj.containsKey('dateTime')) {
        return DateTime.parse(timeObj['dateTime'] as String);
      }
      // All-day event: "2026-03-04" -> start of that day
      return DateTime.parse(timeObj['date'] as String);
    }

    return RawCalendarEvent(
      id: json['id'] as String,
      summary: json['summary'] as String? ?? '(No title)',
      startTime: parseGoogleTime(start),
      endTime: parseGoogleTime(end),
      isAllDay: isAllDay,
    );
  }
}
```

### Convex Backend: calendarEvents Functions
```typescript
// convex/calendarEvents.ts
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// Upsert a calendar event (create or update by googleEventId)
export const upsertEvent = mutation({
  args: {
    userId: v.string(),
    googleEventId: v.string(),
    title: v.string(),
    startTime: v.number(),
    endTime: v.number(),
    status: v.string(),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("calendarEvents")
      .withIndex("by_user_google_id", (q) =>
        q.eq("userId", args.userId).eq("googleEventId", args.googleEventId)
      )
      .first();

    if (existing) {
      await ctx.db.patch(existing._id, {
        title: args.title,
        startTime: args.startTime,
        endTime: args.endTime,
        // Don't overwrite status if already reflected/skipped
        ...(existing.status === "reflected" || existing.status === "skipped"
          ? {}
          : { status: args.status }),
      });
      return existing._id;
    }

    return await ctx.db.insert("calendarEvents", args);
  },
});

// Get un-reflected events for catch-up (since a given timestamp)
export const getUnreflectedEvents = query({
  args: {
    userId: v.string(),
    since: v.number(), // Unix ms
  },
  handler: async (ctx, args) => {
    const events = await ctx.db
      .query("calendarEvents")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    return events.filter(
      (e) =>
        e.endTime >= args.since &&
        e.status !== "reflected" &&
        e.status !== "skipped"
    );
  },
});

// Get today's calendar events
export const getTodayEvents = query({
  args: {
    userId: v.string(),
    startOfDay: v.number(), // Unix ms
  },
  handler: async (ctx, args) => {
    const events = await ctx.db
      .query("calendarEvents")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    return events
      .filter((e) => e.startTime >= args.startOfDay)
      .sort((a, b) => a.startTime - b.startTime);
  },
});

// Update event status (e.g., to "reflected" or "skipped")
export const updateEventStatus = mutation({
  args: {
    eventId: v.string(),
    status: v.string(),
    linkedEntryId: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const event = await ctx.db.get(args.eventId as any);
    if (!event) throw new Error("Event not found");

    await ctx.db.patch(event._id, {
      status: args.status,
      ...(args.linkedEntryId ? { linkedEntryId: args.linkedEntryId } : {}),
    });
  },
});
```

### Entries Table Extension
```typescript
// Update convex/schema.ts entries table to include optional calendarEventId
entries: defineTable({
  userId: v.string(),
  body: v.string(),
  inputMethod: v.string(),
  calendarEventId: v.optional(v.string()), // NEW: link to calendar event
})
  .index("by_user", ["userId"])
  .searchIndex("search_body", { searchField: "body", filterFields: ["userId"] }),
```

### Notification Initialization in main.dart
```dart
// main.dart
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Create container so notification tap handler can access providers
  final container = ProviderContainer();

  await NotificationService.initialize(
    onTap: (response) {
      final calendarEventId = response.payload;
      if (calendarEventId != null && calendarEventId.isNotEmpty) {
        container.read(routerProvider).go('/today?eventId=$calendarEventId');
      }
    },
  );

  // Also check if app was launched by notification tap
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();
  String? initialEventId;
  if (launchDetails?.didNotificationLaunchApp == true) {
    initialEventId = launchDetails?.notificationResponse?.payload;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: App(initialEventId: initialEventId),
    ),
  );
}
```

### AndroidManifest.xml Additions
```xml
<!-- Add to AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Inside <application> tag -->
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| googleapis_auth for Flutter | extension_google_sign_in_as_googleapis_auth v3.0.0 | 2024 | Bridge package specifically for Flutter; but direct HTTP is even simpler |
| google_sign_in v6 signIn() with scopes | v7 authorizeScopes() via authorizationClient | google_sign_in v7 (2024) | Incremental scope grants without re-triggering full sign-in |
| FCM for all notifications | Local notifications for time-based triggers | Ongoing trend | Reduces server dependency; better reliability for known-schedule notifications |
| firebase_messaging manual setup | firebase_messaging v16+ with flutterfire_cli | 2024-2025 | Still requires Firebase project; overkill when notifications are locally triggered |

**Deprecated/outdated:**
- `google_sign_in` v6's `signIn(scopes: [...])` pattern: replaced by `authorizeScopes()` in v7
- `googleapis_auth` direct use in Flutter: officially discouraged; use extension package instead (or direct HTTP)
- `flutter_local_notifications` v19 and earlier: v20.1.0 has breaking API changes (named parameters in `zonedSchedule`)

## Open Questions

1. **All-day event handling**
   - What we know: All-day events use `date` instead of `dateTime` in Google Calendar API response
   - What's unclear: Should they appear in the agenda? They are rarely "meetings" (usually birthdays, holidays)
   - Recommendation: Filter out all-day events from the agenda; they don't warrant reflection nudges. Can revisit if users request it.

2. **Notification ID stability**
   - What we know: flutter_local_notifications requires int IDs. Google Calendar event IDs are strings like "abc123def456".
   - What's unclear: Whether `hashCode` on these strings produces enough uniqueness for typical daily event counts
   - Recommendation: For a typical day (5-15 events), `string.hashCode` collision risk is negligible. Use it with `& 0x7FFFFFFF` to ensure positive int. If issues arise, maintain an int counter in SharedPreferences.

3. **Multi-day event spanning across calendar sync**
   - What we know: Pull-based catch-up checks for events since lastOpenTime, which could span weekends
   - What's unclear: Whether Google Calendar API pagination is needed for users with very busy calendars (>250 events in the catch-up window)
   - Recommendation: Set `maxResults=250` (default). For an intern's calendar over a weekend gap, this is more than sufficient. Log a warning if truncated.

## Sources

### Primary (HIGH confidence)
- [Google Calendar API v3 events.list](https://developers.google.com/workspace/calendar/api/v3/reference/events/list) - REST endpoint, parameters, response format
- [google_sign_in v7.2.0](https://pub.dev/packages/google_sign_in) - authorizeScopes, authorizationForScopes, accessToken API
- [flutter_local_notifications v20.1.0](https://pub.dev/packages/flutter_local_notifications) - zonedSchedule, initialization, notification tap handling
- [Convex Scheduled Functions](https://docs.convex.dev/scheduling/scheduled-functions) - runAfter, scheduler API, limitations
- [Convex HTTP API](https://docs.convex.dev/http-api/) - /api/action endpoint for calling actions from Flutter
- [Flutter official Google APIs guide](https://docs.flutter.dev/data-and-backend/google-apis) - Recommends extension_google_sign_in_as_googleapis_auth for Flutter

### Secondary (MEDIUM confidence)
- [extension_google_sign_in_as_googleapis_auth v3.0.0](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth) - Bridge package; confirmed compatible with google_sign_in v7; we chose direct HTTP instead
- [googleapis v16.0.0](https://pub.dev/packages/googleapis) - CalendarApi class available but not needed for our simple use case
- [Convex Actions docs](https://docs.convex.dev/functions/actions) - fetch() available in actions for external API calls
- [go_router deep linking](https://docs.flutter.dev/ui/navigation/deep-linking) - Query parameters for notification deep links

### Tertiary (LOW confidence)
- [google_sign_in v7 accessToken issue #171835](https://github.com/flutter/flutter/issues/171835) - Confirmed accessToken available on GoogleSignInClientAuthorization but web-specific refresh limitations noted
- Community articles on flutter_local_notifications + go_router navigation patterns - multiple sources agree on the callback + router.go() pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages verified on pub.dev with current versions; google_sign_in already in project; http already in project
- Architecture: HIGH - Client-side Calendar API pattern is well-documented by Google; local notifications pattern is standard Flutter; Convex storage follows existing project patterns
- Pitfalls: HIGH - Token expiry, permission requirements, all-day event parsing, dedup are well-documented issues with known solutions
- Deep linking: MEDIUM - GoRouter query parameter approach is standard but notification tap -> navigation has some nuance around app-not-running state

**Research date:** 2026-03-04
**Valid until:** 2026-04-04 (stable domain; google_sign_in v7 API is settled)
