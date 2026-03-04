import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart' show SubscriptionHandle;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/convex/convex_service.dart';
import '../domain/entry.dart';

// ============================================================================
// User ID Provider
// ============================================================================

/// Extracts the current user's ID from the auth state.
///
/// Returns null if the user is not authenticated. Downstream providers
/// (e.g., [todayEntriesProvider]) watch this to scope queries to the
/// signed-in user.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider).asData?.value;
  if (authState is AuthStateAuthenticated) return authState.userId;
  return null;
});

// ============================================================================
// Today's Entries Provider — real-time subscription
// ============================================================================

/// Provides today's Daily Canvas entries as a real-time stream.
///
/// Subscribes to the Convex `entries:getEntriesToday` query scoped to the
/// current user and today's date (local midnight). The subscription fires
/// [onUpdate] whenever entries change (create, update, delete).
///
/// The stream emits `List<Entry>` sorted newest-first (server-side ordering).
///
/// Automatically cancels the Convex subscription when the provider is disposed
/// (e.g., when the user navigates away from the Today screen).
final todayEntriesProvider = StreamProvider.autoDispose<List<Entry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  // Create a stream controller to bridge Convex subscription callbacks
  // into a Dart Stream that Riverpod can consume.
  final controller = StreamController<List<Entry>>();

  if (userId == null) {
    // Not authenticated — emit empty list and close
    controller.add([]);
    controller.close();
    return controller.stream;
  }

  // Calculate start of today in local time, converted to Unix milliseconds
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfDayMs = startOfDay.millisecondsSinceEpoch;

  // Track the subscription handle for cleanup
  SubscriptionHandle? subHandle;

  // Start the Convex subscription
  ConvexService.instance
      .subscribe(
        name: 'entries:getEntriesToday',
        args: {
          'userId': userId,
          'startOfDay': startOfDayMs,
        },
        onUpdate: (String value) {
          try {
            final decoded = json.decode(value);
            if (decoded is List) {
              final entries = decoded
                  .cast<Map<String, dynamic>>()
                  .map(Entry.fromJson)
                  .toList();
              if (!controller.isClosed) {
                controller.add(entries);
              }
            } else {
              if (!controller.isClosed) {
                controller.add([]);
              }
            }
          } catch (e) {
            debugPrint('[todayEntriesProvider] parse error: $e');
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        },
        onError: (String message, String? value) {
          debugPrint('[todayEntriesProvider] subscription error: $message');
          if (!controller.isClosed) {
            controller.addError(Exception(message));
          }
        },
      )
      .then((handle) {
        subHandle = handle;
      })
      .catchError((Object e) {
        debugPrint('[todayEntriesProvider] subscribe failed: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      });

  // Cleanup: cancel the Convex subscription and close the stream controller
  ref.onDispose(() {
    subHandle?.cancel();
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream;
});
