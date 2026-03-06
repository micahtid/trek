import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/convex/convex_service.dart';
import '../domain/entry.dart';

// ============================================================================
// User ID Provider
// ============================================================================

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider).asData?.value;
  if (authState is AuthStateAuthenticated) return authState.userId;
  return null;
});

// ============================================================================
// Today's Entries Provider — HTTP fetch (replaces WebSocket subscription)
// ============================================================================

/// Provides today's Daily Canvas entries via a single HTTP query.
///
/// Fetches on mount and whenever invalidated (e.g., after create/update/delete).
/// Call `ref.invalidate(todayEntriesProvider)` to refresh.
final todayEntriesProvider = FutureProvider.autoDispose<List<Entry>>((ref) async {
  // Keep cached across tab switches; only refetch on explicit invalidation
  ref.keepAlive();

  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfDayMs = startOfDay.millisecondsSinceEpoch;

  try {
    final result = await ConvexHttpService.instance.query(
      path: 'entries:getEntriesToday',
      args: {
        'userId': userId,
        'startOfDay': startOfDayMs,
      },
    );

    if (result is List) {
      return result
          .cast<Map<String, dynamic>>()
          .map(Entry.fromJson)
          .toList();
    }
    return [];
  } catch (e) {
    debugPrint('[todayEntriesProvider] query error: $e');
    rethrow;
  }
});
