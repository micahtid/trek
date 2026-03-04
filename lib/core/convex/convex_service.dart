import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:convex_flutter/convex_flutter.dart';

const String kConvexDeploymentUrl = 'https://grand-tortoise-682.convex.cloud';

/// Ensures ConvexClient is initialized exactly once.
/// Returns true if ready, false if initialization failed.
Future<bool> ensureConvexInitialized() async {
  if (_convexInitialized) return true;
  if (_convexInitFailed) return false;

  try {
    await ConvexClient.initialize(
      const ConvexConfig(
        deploymentUrl: kConvexDeploymentUrl,
        clientId: 'intern-growth-vault-flutter',
      ),
    ).timeout(const Duration(seconds: 10));
    _convexInitialized = true;
    return true;
  } catch (e) {
    debugPrint('[ConvexService] initialization failed: $e');
    _convexInitFailed = true;
    return false;
  }
}

bool _convexInitialized = false;
bool _convexInitFailed = false;

class ConvexService {
  ConvexService._();

  static final ConvexService instance = ConvexService._();

  AuthHandleWrapper? _authHandle;

  Future<void> setupAuth({
    required Future<String?> Function() fetchToken,
    void Function(bool isAuthenticated)? onAuthChange,
  }) async {
    final ready = await ensureConvexInitialized();
    if (!ready) {
      debugPrint('[ConvexService] skipping setupAuth — Convex not initialized');
      return;
    }
    _authHandle?.dispose();
    _authHandle = await ConvexClient.instance.setAuthWithRefresh(
      fetchToken: fetchToken,
      onAuthChange: onAuthChange,
    );
  }

  Future<void> clearAuth() async {
    _authHandle?.dispose();
    _authHandle = null;
    if (_convexInitialized) {
      await ConvexClient.instance.clearAuth();
    }
  }

  bool get isAuthenticated => _authHandle?.isAuthenticated ?? false;

  Future<String> mutation({
    required String name,
    required Map<String, dynamic> args,
  }) async {
    final ready = await ensureConvexInitialized();
    if (!ready) throw StateError('Convex not initialized');
    return ConvexClient.instance.mutation(name: name, args: args);
  }

  Future<String> query(String name, Map<String, dynamic> args) async {
    final ready = await ensureConvexInitialized();
    if (!ready) throw StateError('Convex not initialized');
    return ConvexClient.instance.query(name, args);
  }

  /// Subscribes to a Convex query for real-time updates.
  ///
  /// Returns a [SubscriptionHandle] whose [cancel] method should be called
  /// when the subscription is no longer needed (e.g., in `ref.onDispose`).
  ///
  /// [onUpdate] fires with a JSON string whenever the query result changes.
  /// [onError] fires with an error message and optional value.
  Future<SubscriptionHandle> subscribe({
    required String name,
    required Map<String, dynamic> args,
    required void Function(String value) onUpdate,
    required void Function(String message, String? value) onError,
  }) async {
    final ready = await ensureConvexInitialized();
    if (!ready) throw StateError('Convex not initialized');
    return ConvexClient.instance.subscribe(
      name: name,
      args: args,
      onUpdate: onUpdate,
      onError: onError,
    );
  }
}
