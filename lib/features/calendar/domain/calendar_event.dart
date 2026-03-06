/// A calendar event synced from Google Calendar and persisted in Convex.
///
/// Has two factory constructors:
/// - [fromJson]: parses a Convex document (used when reading from Convex)
/// - [fromGoogleJson]: parses a Google Calendar API response item (used during sync)
///
/// Status lifecycle: upcoming -> in_progress -> ended -> reflected/skipped
class CalendarEvent {
  /// Convex document _id (e.g., "j57abc123...").
  final String id;

  /// Google ID of the owning user.
  final String userId;

  /// Google Calendar event ID — used for dedup on upsert.
  final String googleEventId;

  /// Event summary/title from Google Calendar.
  final String title;

  /// Event start time in Unix milliseconds.
  final int startTime;

  /// Event end time in Unix milliseconds.
  final int endTime;

  /// Event status: "upcoming", "in_progress", "ended", "reflected", or "skipped".
  final String status;

  /// Convex entry _id if the user has reflected on this event.
  final String? linkedEntryId;

  /// Convex _creationTime in Unix milliseconds.
  final int creationTime;

  /// Whether this is an all-day event (no specific time).
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.googleEventId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.linkedEntryId,
    required this.creationTime,
    this.isAllDay = false,
  });

  /// Parses a Convex document JSON map into a [CalendarEvent].
  ///
  /// Expected keys: `_id`, `userId`, `googleEventId`, `title`, `startTime`,
  /// `endTime`, `status`, `linkedEntryId` (optional), `_creationTime`.
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      googleEventId: json['googleEventId'] as String,
      title: json['title'] as String,
      startTime: (json['startTime'] as num).toInt(),
      endTime: (json['endTime'] as num).toInt(),
      status: json['status'] as String,
      linkedEntryId: json['linkedEntryId'] as String?,
      creationTime: (json['_creationTime'] as num).toInt(),
    );
  }

  /// Parses a Google Calendar API event item into a [CalendarEvent].
  ///
  /// Google Calendar API returns:
  /// - Timed events: `start.dateTime` / `end.dateTime` (ISO 8601 with timezone)
  /// - All-day events: `start.date` / `end.date` (YYYY-MM-DD)
  ///
  /// The event `id` field becomes [googleEventId].
  /// Convex fields ([id], [userId], [creationTime], [status]) are set to
  /// placeholder values since this is pre-persistence.
  factory CalendarEvent.fromGoogleJson(Map<String, dynamic> json) {
    final start = json['start'] as Map<String, dynamic>;
    final end = json['end'] as Map<String, dynamic>;

    final bool allDay = start.containsKey('date') && !start.containsKey('dateTime');

    int startMs;
    int endMs;

    if (allDay) {
      // All-day events: "date" is "YYYY-MM-DD"
      startMs = DateTime.parse(start['date'] as String).millisecondsSinceEpoch;
      endMs = DateTime.parse(end['date'] as String).millisecondsSinceEpoch;
    } else {
      // Timed events: "dateTime" is ISO 8601 with timezone
      startMs = DateTime.parse(start['dateTime'] as String).millisecondsSinceEpoch;
      endMs = DateTime.parse(end['dateTime'] as String).millisecondsSinceEpoch;
    }

    return CalendarEvent(
      id: '', // Not yet persisted to Convex
      userId: '', // Set by caller during upsert
      googleEventId: json['id'] as String,
      title: (json['summary'] as String?) ?? '(No title)',
      startTime: startMs,
      endTime: endMs,
      status: 'upcoming', // Will be computed by caller
      creationTime: 0, // Not yet persisted
      isAllDay: allDay,
    );
  }

  /// Event start time as a [DateTime] (local timezone).
  DateTime get startAt => DateTime.fromMillisecondsSinceEpoch(startTime);

  /// Event end time as a [DateTime] (local timezone).
  DateTime get endAt => DateTime.fromMillisecondsSinceEpoch(endTime);

  /// Whether this event has already ended.
  bool get hasEnded => DateTime.now().millisecondsSinceEpoch > endTime;

  /// Whether this event needs reflection (status is "ended").
  bool get needsReflection => status == 'ended';

  /// Whether the user has already reflected on this event.
  bool get isReflected => status == 'reflected';

  /// Whether the user has skipped reflecting on this event.
  bool get isSkipped => status == 'skipped';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: "$title", status: $status)';
}
