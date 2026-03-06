import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/calendar_event.dart';

// ============================================================================
// Exceptions
// ============================================================================

/// Base exception for Google Calendar API errors.
class CalendarApiException implements Exception {
  final String message;
  const CalendarApiException(this.message);

  @override
  String toString() => 'CalendarApiException: $message';
}

/// Thrown when the Google Calendar API returns 401 (access token expired).
/// The caller should request a fresh token via authorizeScopes and retry.
class CalendarAuthExpiredException extends CalendarApiException {
  const CalendarAuthExpiredException()
      : super('Google Calendar access token expired (401)');
}

// ============================================================================
// Repository
// ============================================================================

/// Fetches calendar events from the Google Calendar REST API.
///
/// Uses Bearer token authentication. All methods filter out all-day events
/// since they rarely warrant reflections.
class CalendarRepository {
  static const _baseUrl =
      'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  /// Fetches today's timed events from the user's primary Google Calendar.
  ///
  /// Returns events sorted by start time (ascending). All-day events are
  /// excluded since they rarely need reflection.
  ///
  /// Throws [CalendarAuthExpiredException] on 401 (token expired).
  /// Throws [CalendarApiException] on other HTTP errors.
  Future<List<CalendarEvent>> fetchTodayEvents(String accessToken) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _fetchEvents(
      accessToken: accessToken,
      timeMin: startOfDay.toUtc().toIso8601String(),
      timeMax: endOfDay.toUtc().toIso8601String(),
    );
  }

  /// Fetches timed events since [since] up to now.
  ///
  /// Used by the catch-up flow to find events the user missed while the
  /// app was closed.
  Future<List<CalendarEvent>> fetchEventsSince(
    String accessToken,
    DateTime since,
  ) async {
    return _fetchEvents(
      accessToken: accessToken,
      timeMin: since.toUtc().toIso8601String(),
      timeMax: DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Internal: fetches events from Google Calendar API with the given time range.
  Future<List<CalendarEvent>> _fetchEvents({
    required String accessToken,
    required String timeMin,
    required String timeMax,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'timeMin': timeMin,
      'timeMax': timeMax,
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'fields': 'items(id,summary,start,end,status)',
    });

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 401) {
      throw const CalendarAuthExpiredException();
    }

    if (response.statusCode != 200) {
      throw CalendarApiException(
        'Google Calendar API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];

    return items
        .cast<Map<String, dynamic>>()
        .map(CalendarEvent.fromGoogleJson)
        .where((e) => !e.isAllDay) // Filter out all-day events
        .toList();
  }
}

/// Riverpod provider for [CalendarRepository] -- simple singleton, no deps.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});
