import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../../core/convex/convex_service.dart';
import '../../settings/calendar_auth_section.dart';
import '../../settings/github_auth_section.dart';

const _kLastSignedInUserKey = 'last_signed_in_google_id';

class AuthNotifier extends AsyncNotifier<AuthState> {
  StreamSubscription<AuthEvent>? _authEventSubscription;

  @override
  Future<AuthState> build() async {
    ref.onDispose(() {
      _authEventSubscription?.cancel();
    });

    final repo = ref.read(authRepositoryProvider);

    // Initialize Google Sign-In and attempt silent sign-in
    await repo.initialize();

    // Set token on Convex HTTP service if we already have one from silent sign-in
    if (repo.currentIdToken != null) {
      ConvexHttpService.instance.setToken(repo.currentIdToken);
    }

    // Subscribe to future auth events (sign-in/out after initial load)
    _authEventSubscription = repo.authEvents.listen(_handleAuthEvent);

    return state.asData?.value ?? const AuthStateUnauthenticated();
  }

  void _handleAuthEvent(AuthEvent event) {
    switch (event) {
      case AuthEventSignedIn():
        _onSignedIn(event);
      case AuthEventSignedOut():
        ConvexHttpService.instance.clearToken();
        state = const AsyncData(AuthStateUnauthenticated());
      case AuthEventError():
        debugPrint('[AuthNotifier] Auth error: ${event.error}');
        if (state.isLoading || state.asData?.value is AuthStateLoading) {
          state = const AsyncData(AuthStateUnauthenticated());
        }
    }
  }

  Future<void> _onSignedIn(AuthEventSignedIn event) async {
    state = const AsyncData(AuthStateLoading());

    // Set token for all subsequent Convex HTTP calls
    ConvexHttpService.instance.setToken(event.idToken);

    // Clear connections if a different user signed in
    await _clearConnectionsIfUserChanged(event.googleId);

    try {
      final result = await ConvexHttpService.instance.mutation(
        path: 'users:upsertUser',
        args: {
          'googleId': event.googleId,
          'email': event.email,
          'name': event.displayName,
          if (event.avatarUrl != null) 'avatarUrl': event.avatarUrl,
        },
      );

      // result is the Convex document _id (a string)
      final String userId = result is String ? result : result.toString();

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
      // If Convex upsert fails, stay unauthenticated — don't fake auth
      ConvexHttpService.instance.clearToken();
      state = const AsyncData(AuthStateUnauthenticated());
    }
  }

  Future<void> _clearConnectionsIfUserChanged(String currentGoogleId) async {
    const storage = FlutterSecureStorage();
    final lastUserId = await storage.read(key: _kLastSignedInUserKey);

    if (lastUserId != currentGoogleId) {
      // Different user (or first run of this check) — clear connections
      ref.read(calendarConnectedProvider.notifier).setConnected(false);
      await ref.read(gitHubConnectionProvider.notifier).disconnect();
    }

    // Store current user for next comparison
    await storage.write(key: _kLastSignedInUserKey, value: currentGoogleId);
  }

  Future<void> signIn() async {
    state = const AsyncData(AuthStateLoading());
    final repo = ref.read(authRepositoryProvider);
    await repo.signIn();
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    ConvexHttpService.instance.clearToken();
    state = const AsyncData(AuthStateUnauthenticated());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
