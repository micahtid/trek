import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/convex/convex_service.dart';

/// Entry point.
///
/// Convex must be initialized before any Riverpod providers attempt to use it.
/// initConvexClient() creates the singleton ConvexClient with the deployment URL.
/// Auth bridge (setAuthWithRefresh) is set up lazily by AuthNotifier when it builds.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Convex client singleton before the app starts
  // This must complete before any ConvexClient.instance calls
  await initConvexClient();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
