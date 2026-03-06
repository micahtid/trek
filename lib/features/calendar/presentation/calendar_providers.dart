import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/notification_service.dart';
import '../../today/presentation/entry_providers.dart';
import '../data/calendar_event_repository.dart';
import '../data/calendar_repository.dart';
import '../domain/calendar_event.dart';

// ============================================================================
// Google Calendar Access Token Helper
// ============================================================================

/// Calendar read-only scope — same as used in CalendarAuthSection.
const _calendarReadonlyScope =
    'https://www.googleapis.com/auth/calendar.readonly';

/// Retrieves a valid Google Calendar access token.
///
/// First checks if the scope is already authorized. If not, requests
/// authorization via Google's incremental scope UI.
///
/// Throws if the user declines or if no access token is available.
Future<String> getCalendarAccessToken() async {
  final client = GoogleSignIn.instance.authorizationClient;

  // Check if already authorized — non-interactive only.
  // If the user hasn't granted calendar scope in Settings, this returns null
  // and we throw so the provider returns [] (no consent dialog popup).
  final authorization =
      await client.authorizationForScopes([_calendarReadonlyScope]);

  if (authorization == null) {
    throw StateError('Calendar scope not granted');
  }

  return authorization.accessToken;
}

// ============================================================================
// Today's Calendar Events Provider
// ============================================================================

/// Provides today's calendar events synced from Google Calendar and persisted
/// to Convex.
///
/// Flow:
/// 1. Get access token (may trigger consent UI on first call)
/// 2. Fetch today's events from Google Calendar API
/// 3. Upsert each event into Convex (with computed status)
/// 4. Query Convex for today's events (source of truth after upsert)
/// 5. Return the Convex events list
///
/// On [CalendarAuthExpiredException], retries once with a fresh token.
/// If Calendar is not connected (scope not granted), returns empty list.
final todayCalendarEventsProvider =
    FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final calendarRepo = ref.read(calendarRepositoryProvider);
  final eventRepo = ref.read(calendarEventRepositoryProvider);

  try {
    final accessToken = await getCalendarAccessToken();

    // Fetch from Google Calendar API
    List<CalendarEvent> googleEvents;
    try {
      googleEvents = await calendarRepo.fetchTodayEvents(accessToken);
    } on CalendarAuthExpiredException {
      // Token expired — request fresh token and retry once
      final freshToken = await _refreshCalendarToken();
      googleEvents = await calendarRepo.fetchTodayEvents(freshToken);
    }

    // Upsert each event into Convex with computed status
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final event in googleEvents) {
      String status;
      if (event.endTime < nowMs) {
        status = 'ended';
      } else if (event.startTime < nowMs) {
        status = 'in_progress';
      } else {
        status = 'upcoming';
      }

      await eventRepo.upsertEvent(
        userId: userId,
        googleEventId: event.googleEventId,
        title: event.title,
        startTime: event.startTime,
        endTime: event.endTime,
        status: status,
      );
    }

    // Query Convex for today's events (source of truth after upsert)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return await eventRepo.getTodayEvents(
      userId: userId,
      startOfDay: startOfDay.millisecondsSinceEpoch,
    );
  } catch (e) {
    // If Calendar is not connected (scope not granted), return empty list
    // rather than propagating the error
    debugPrint('[todayCalendarEventsProvider] error: $e');
    return [];
  }
});

// ============================================================================
// Unreflected Events Provider
// ============================================================================

/// Provides calendar events that ended since the last app open but have not
/// been reflected on or skipped.
///
/// Uses SharedPreferences to track `lastOpenTime`. On each call:
/// 1. Read lastOpenTime (default: start of today)
/// 2. Query Convex for unreflected events since lastOpenTime
/// 3. Update lastOpenTime to now
/// 4. Return the events
final unreflectedEventsProvider =
    FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final eventRepo = ref.read(calendarEventRepositoryProvider);

  try {
    final prefs = await SharedPreferences.getInstance();

    // Default to start of today if no lastOpenTime stored
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final lastOpenMs = prefs.getInt('lastOpenTime') ??
        startOfToday.millisecondsSinceEpoch;

    // Query Convex for unreflected events
    final events = await eventRepo.getUnreflectedEvents(
      userId: userId,
      since: lastOpenMs,
    );

    // Update lastOpenTime to now
    await prefs.setInt('lastOpenTime', now.millisecondsSinceEpoch);

    return events;
  } catch (e) {
    debugPrint('[unreflectedEventsProvider] error: $e');
    return [];
  }
});

// ============================================================================
// Notification Scheduling Provider
// ============================================================================

/// Schedules local push notifications for today's upcoming/in-progress events.
///
/// Runs as a side effect when calendar events are loaded. Respects the
/// reflectionRemindersEnabled setting from SharedPreferences.
final calendarNotificationSchedulerProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final events = await ref.watch(todayCalendarEventsProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final remindersEnabled =
      prefs.getBool('reflectionRemindersEnabled') ?? true;
  if (!remindersEnabled) return;

  for (final event in events) {
    if (event.status == 'upcoming' || event.status == 'in_progress') {
      await NotificationService.scheduleReflectionNudge(
        calendarEventId: event.id,
        eventTitle: event.title,
        eventEndTime: event.endAt,
      );
    }
  }
});

// ============================================================================
// Reflection Reminders Setting Provider
// ============================================================================

/// Provides the current reflection reminders enabled state from SharedPreferences.
final reflectionRemindersEnabledProvider =
    FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('reflectionRemindersEnabled') ?? true;
});

// ============================================================================
// Helpers
// ============================================================================

/// Requests a fresh Calendar access token (non-interactive).
Future<String> _refreshCalendarToken() async {
  final authorization = await GoogleSignIn.instance.authorizationClient
      .authorizationForScopes([_calendarReadonlyScope]);
  if (authorization == null) {
    throw StateError('Calendar scope not granted');
  }
  return authorization.accessToken;
}
