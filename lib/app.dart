import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/presentation/calendar_providers.dart';

/// Root application widget.
///
/// Configures Material theming, GoRouter, and observes app lifecycle to
/// refresh calendar data when the app is resumed from background.
class App extends ConsumerStatefulWidget {
  /// Optional calendar event ID passed when the app was launched via
  /// a notification tap. Triggers deep-link navigation after the first frame.
  final String? initialEventId;

  const App({super.key, this.initialEventId});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // If launched from a notification, navigate after the first frame
    if (widget.initialEventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(routerProvider)
            .go('/today?eventId=${widget.initialEventId}');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh calendar data on resume for fresh sync and catch-up
      ref.invalidate(todayCalendarEventsProvider);
      ref.invalidate(unreflectedEventsProvider);

      // Update lastOpenTime for unreflected events tracking
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt(
          'lastOpenTime',
          DateTime.now().millisecondsSinceEpoch,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Intern Vault',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
