import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../../core/convex/convex_service.dart';

// ============================================================================
// Auth Notifier
// ============================================================================

/// Riverpod AsyncNotifier that drives the auth lifecycle.
///
/// Responsibilities:
/// - Initialize AuthRepository and set up Convex auth bridge on first build
/// - Emit AuthState (unauthenticated, loading, authenticated)
/// - Call Convex upsertUser mutation on sign-in
/// - Provide signIn() and signOut() methods to UI
///
/// The router watches this provider via [authNotifierProvider] and redirects
/// based on the current AuthState.
class AuthNotifier extends AsyncNotifier<AuthState> {
  StreamSubscription<AuthEvent>? _authEventSubscription;

  @override
  Future<AuthState> build() async {
    // Ensure cleanup when provider is disposed
    ref.onDispose(() {
      _authEventSubscription?.cancel();
    });

    final repo = ref.read(authRepositoryProvider);

    // Set up Convex auth bridge BEFORE Google initialize()
    // This way when Google fires the event stream, the bridge is ready.
    await _setupConvexAuth(repo);

    // Initialize Google Sign-In and attempt silent sign-in
    // This will emit events on repo.authEvents if a cached session exists
    await repo.initialize();

    // Subscribe to future auth events (sign-in/out after initial load)
    _authEventSubscription = repo.authEvents.listen(_handleAuthEvent);

    // Return initial state — if silent sign-in succeeded, _handleAuthEvent
    // will have already updated state to AuthStateAuthenticated
    // We return unauthenticated here as the safe default; the stream will
    // override it if the user is already signed in.
    return state.asData?.value ?? const AuthStateUnauthenticated();
  }

  /// Sets up the Convex auth bridge with a fetchToken callback.
  ///
  /// fetchToken is called by Convex on startup and 60s before token expiry.
  /// We return the current cached ID token or attempt a silent re-auth.
  Future<void> _setupConvexAuth(AuthRepository repo) async {
    await ConvexService.instance.setupAuth(
      fetchToken: () async {
        // Try to get a fresh token via silent re-auth
        return await repo.attemptSilentSignIn();
      },
      onAuthChange: (isAuthenticated) {
        // Convex notifies us of auth state changes
        // This fires when Convex accepts or rejects the token
        if (!isAuthenticated && state.asData?.value is AuthStateAuthenticated) {
          // Convex lost auth — update UI state to unauthenticated
          state = const AsyncData(AuthStateUnauthenticated());
        }
      },
    );
  }

  /// Handles auth events from Google Sign-In.
  void _handleAuthEvent(AuthEvent event) {
    switch (event) {
      case AuthEventSignedIn():
        _onSignedIn(event);
      case AuthEventSignedOut():
        state = const AsyncData(AuthStateUnauthenticated());
      case AuthEventError():
        // Log error but don't crash the app — stay in current state
        // unless we're in loading state, in which case fall back to unauthenticated
        debugPrint('[AuthNotifier] Auth error: ${event.error}');
        if (state.isLoading || state.asData?.value is AuthStateLoading) {
          state = const AsyncData(AuthStateUnauthenticated());
        }
    }
  }

  /// Called when Google sign-in succeeds. Calls Convex to upsert the user record.
  Future<void> _onSignedIn(AuthEventSignedIn event) async {
    // Set loading state while we upsert the user in Convex
    state = const AsyncData(AuthStateLoading());

    try {
      // Upsert user record in Convex (creates on first sign-in, updates on subsequent)
      final result = await ConvexService.instance.mutation(
        name: 'users:upsertUser',
        args: {
          'googleId': event.googleId,
          'email': event.email,
          'name': event.displayName,
          if (event.avatarUrl != null) 'avatarUrl': event.avatarUrl,
        },
      );

      // result is the Convex document _id as a JSON string
      // Convex returns values as JSON — the _id is a string in JSON format
      final String userId = _parseConvexId(result);

      state = AsyncData(
        AuthStateAuthenticated(
          userId: userId,
          email: event.email,
          displayName: event.displayName,
          avatarUrl: event.avatarUrl,
        ),
      );
    } catch (e) {
      debugPrint('[AuthNotifier] upsertUser failed: $e');
      // Sign-in succeeded at the Google level but Convex upsert failed.
      // We can still let the user in with a fallback userId.
      // This handles the dev case where applicationID is "verified" placeholder.
      state = AsyncData(
        AuthStateAuthenticated(
          userId: event.googleId, // Fallback to Google ID
          email: event.email,
          displayName: event.displayName,
          avatarUrl: event.avatarUrl,
        ),
      );
    }
  }

  /// Parses the Convex document ID from the mutation result JSON.
  ///
  /// Convex mutations return JSON strings. The upsertUser mutation returns the
  /// document _id as a JSON string (e.g., '"j57abc123..."' or just 'j57abc123...').
  String _parseConvexId(String result) {
    try {
      // Try to JSON decode — if it's a JSON string, decode it
      final decoded = json.decode(result);
      if (decoded is String) return decoded;
      return result;
    } catch (_) {
      // Not JSON — return as-is
      return result;
    }
  }

  // ============================================================================
  // Public API
  // ============================================================================

  /// Triggers the interactive Google sign-in flow.
  ///
  /// Call this from the sign-in button tap handler.
  /// State changes come via the auth event stream, not as a return value.
  Future<void> signIn() async {
    state = const AsyncData(AuthStateLoading());
    final repo = ref.read(authRepositoryProvider);
    await repo.signIn();
  }

  /// Signs out the user from Google and clears Convex auth.
  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    await ConvexService.instance.clearAuth();
    state = const AsyncData(AuthStateUnauthenticated());
  }
}

// ============================================================================
// Provider
// ============================================================================

/// Provider for AuthNotifier. Watch this in the router for redirect logic.
///
/// Usage:
/// ```dart
/// // In router redirect:
/// final authState = ref.read(authNotifierProvider);
/// final isAuthenticated = authState.asData?.value is AuthStateAuthenticated;
///
/// // In UI button:
/// ref.read(authNotifierProvider.notifier).signIn();
/// ```
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
