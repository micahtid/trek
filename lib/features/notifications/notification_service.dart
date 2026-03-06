import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Static service for scheduling local push notifications.
///
/// Handles initialization (platform-specific settings, permission requests),
/// scheduling timezone-aware reflection nudges after calendar events end,
/// and cancellation.
///
/// Uses [FlutterLocalNotificationsPlugin] under the hood.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Android notification channel for reflection nudges.
  static const _channelId = 'reflection_nudges';
  static const _channelName = 'Reflection Reminders';
  static const _channelDescription =
      'Nudges you to reflect after calendar events end';

  /// Initializes the notification plugin and requests permission.
  ///
  /// Must be called once during app startup (e.g., in main.dart).
  ///
  /// [onTap] is invoked when the user taps a notification. The
  /// [NotificationResponse.payload] contains the calendarEventId.
  static Future<void> initialize({
    required void Function(NotificationResponse) onTap,
  }) async {
    // Initialize timezone data for zonedSchedule
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS / macOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onTap,
    );

    // Request notification permission on Android 13+ (API 33)
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Schedules a reflection nudge 5 minutes after [eventEndTime].
  ///
  /// If the scheduled time is already in the past, no notification is
  /// scheduled (the event was too long ago for a nudge to be useful).
  ///
  /// The notification payload is [calendarEventId] so the tap handler
  /// can navigate to the correct event's reflection sheet.
  static Future<void> scheduleReflectionNudge({
    required String calendarEventId,
    required String eventTitle,
    required DateTime eventEndTime,
  }) async {
    final scheduledTime = eventEndTime.add(const Duration(minutes: 5));

    // Don't schedule notifications in the past
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Notification ID: positive int derived from calendarEventId
    final notificationId = calendarEventId.hashCode & 0x7FFFFFFF;

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'How did it go?',
      body: 'Hey, how did $eventTitle go?',
      scheduledDate: tzScheduledTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: calendarEventId,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels all pending notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancels the notification for a specific calendar event.
  static Future<void> cancelForEvent(String calendarEventId) async {
    final notificationId = calendarEventId.hashCode & 0x7FFFFFFF;
    await _plugin.cancel(id: notificationId);
  }
}
