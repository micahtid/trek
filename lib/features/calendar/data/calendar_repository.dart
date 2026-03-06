import 'dart:convert';

import 'package:flutter/foundation.dart';
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
///
/// Calendar IDs are cached for the session to avoid redundant API calls.
class CalendarRepository {
  /// Cached calendar IDs — cleared on sign-out or explicit cache clear.
  List<String>? _cachedCalendarIds;

  /// Clears the cached calendar IDs (e.g., on sign-out).
  void clearCache() => _cachedCalendarIds = null;

  /// Fetches today's timed events from all of the user's Google Calendars.
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

    final timeMin = startOfDay.toUtc().toIso8601String();
    final timeMax = endOfDay.toUtc().toIso8601String();

    // Fetch all calendars the user has access to
    final calendarIds = await _fetchCalendarIds(accessToken);

    // Fetch events from all calendars in parallel
    final futures = calendarIds.map((calendarId) => _fetchEvents(
      accessToken: accessToken,
      timeMin: timeMin,
      timeMax: timeMax,
      calendarId: calendarId,
    ));
    final results = await Future.wait(futures);

    // Merge and sort by start time
    final allEvents = results.expand((e) => e).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return allEvents;
  }

  /// Fetches the list of calendar IDs the user has access to.
  /// Results are cached for the session.
  Future<List<String>> _fetchCalendarIds(String accessToken) async {
    if (_cachedCalendarIds != null) return _cachedCalendarIds!;

    final uri = Uri.parse(
      'https://www.googleapis.com/calendar/v3/users/me/calendarList'
    ).replace(queryParameters: {
      'fields': 'items(id,summary,primary)',
    });

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      debugPrint('[Calendar] calendarList error: ${response.statusCode}');
      return ['primary'];
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];

    _cachedCalendarIds = items
        .cast<Map<String, dynamic>>()
        .map((item) => item['id'] as String)
        .toList();
    return _cachedCalendarIds!;
  }

  /// Fetches timed events since [since] up to now.
  ///
  /// Used by the catch-up flow to find events the user missed while the
  /// app was closed.
  Future<List<CalendarEvent>> fetchEventsSince(
    String accessToken,
    DateTime since,
  ) async {
    final timeMin = since.toUtc().toIso8601String();
    final timeMax = DateTime.now().toUtc().toIso8601String();

    final calendarIds = await _fetchCalendarIds(accessToken);
    final futures = calendarIds.map((calendarId) => _fetchEvents(
      accessToken: accessToken,
      timeMin: timeMin,
      timeMax: timeMax,
      calendarId: calendarId,
    ));
    final results = await Future.wait(futures);

    return results.expand((e) => e).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Internal: fetches events from Google Calendar API with the given time range.
  Future<List<CalendarEvent>> _fetchEvents({
    required String accessToken,
    required String timeMin,
    required String timeMax,
    String calendarId = 'primary',
  }) async {
    final baseUrl = 'https://www.googleapis.com/calendar/v3/calendars/${Uri.encodeComponent(calendarId)}/events';
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
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

    final allEvents = items
        .cast<Map<String, dynamic>>()
        .map(CalendarEvent.fromGoogleJson)
        .toList();
    return allEvents.where((e) => !e.isAllDay).toList();
  }
}

/// Riverpod provider for [CalendarRepository] -- simple singleton, no deps.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});
