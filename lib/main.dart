import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'core/router/app_router.dart';
import 'features/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for notification scheduling
  tz.initializeTimeZones();

  // Create a ProviderContainer so notification tap handler can access
  // providers outside the widget tree.
  final container = ProviderContainer();

  // Initialize local notifications with tap handler
  await NotificationService.initialize(
    onTap: (response) {
      final calendarEventId = response.payload;
      if (calendarEventId != null && calendarEventId.isNotEmpty) {
        container
            .read(routerProvider)
            .go('/today?eventId=$calendarEventId');
      }
    },
  );

  // Check if app was launched via notification tap
  String? initialEventId;
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      initialEventId = payload;
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: App(initialEventId: initialEventId),
    ),
  );
}
