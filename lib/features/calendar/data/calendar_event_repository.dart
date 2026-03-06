import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_service.dart';
import '../domain/calendar_event.dart';

/// Bridges Convex CRUD operations for calendarEvents to Dart async methods.
///
/// All methods call [ConvexHttpService.instance] — same pattern as
/// [EntryRepository]. The Convex backend must have calendarEvents.ts deployed.
class CalendarEventRepository {
  /// Upserts a calendar event into Convex.
  ///
  /// If an event with the same (userId, googleEventId) already exists,
  /// updates title/times but preserves user-decided statuses.
  /// Returns the Convex document _id.
  Future<String> upsertEvent({
    required String userId,
    required String googleEventId,
    required String title,
    required int startTime,
    required int endTime,
    required String status,
  }) async {
    final result = await ConvexHttpService.instance.mutation(
      path: 'calendarEvents:upsertEvent',
      args: {
        'userId': userId,
        'googleEventId': googleEventId,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
      },
    );
    return result is String ? result : result.toString();
  }

  /// Returns today's calendar events for a user from Convex.
  ///
  /// Events are sorted ascending by startTime (server-side).
  Future<List<CalendarEvent>> getTodayEvents({
    required String userId,
    required int startOfDay,
  }) async {
    final result = await ConvexHttpService.instance.query(
      path: 'calendarEvents:getTodayEvents',
      args: {
        'userId': userId,
        'startOfDay': startOfDay,
      },
    );

    if (result is List) {
      return result
          .cast<Map<String, dynamic>>()
          .map(CalendarEvent.fromJson)
          .toList();
    }
    return [];
  }

  /// Returns unreflected calendar events since [since] from Convex.
  ///
  /// Events with status "reflected" or "skipped" are excluded server-side.
  Future<List<CalendarEvent>> getUnreflectedEvents({
    required String userId,
    required int since,
  }) async {
    final result = await ConvexHttpService.instance.query(
      path: 'calendarEvents:getUnreflectedEvents',
      args: {
        'userId': userId,
        'since': since,
      },
    );

    if (result is List) {
      return result
          .cast<Map<String, dynamic>>()
          .map(CalendarEvent.fromJson)
          .toList();
    }
    return [];
  }

  /// Updates the status (and optionally linkedEntryId) of a calendar event.
  Future<void> updateEventStatus({
    required String eventId,
    required String status,
    String? linkedEntryId,
  }) async {
    final args = <String, dynamic>{
      'eventId': eventId,
      'status': status,
    };
    if (linkedEntryId != null) {
      args['linkedEntryId'] = linkedEntryId;
    }

    await ConvexHttpService.instance.mutation(
      path: 'calendarEvents:updateEventStatus',
      args: args,
    );
  }
}

/// Riverpod provider for [CalendarEventRepository] -- simple singleton, no deps.
final calendarEventRepositoryProvider =
    Provider<CalendarEventRepository>((ref) {
  return CalendarEventRepository();
});
