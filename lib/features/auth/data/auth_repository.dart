import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ============================================================================
// Google OAuth Configuration
// ============================================================================

/// Web OAuth 2.0 Client ID from Google Cloud Console.
///
/// SETUP REQUIRED: Replace this placeholder with your actual Web Client ID.
/// Format: NUMBERS-HASH.apps.googleusercontent.com
///
/// This MUST match the `applicationID` in convex/auth.config.ts and the
/// `serverClientId` passed to GoogleSignIn.instance.initialize().
///
/// Get it from: Google Cloud Console > APIs & Services > Credentials
///   > Create Credentials > OAuth 2.0 Client ID > Web application
///
/// See: .planning/phases/01-foundation-and-auth/01-RESEARCH.md (Pitfall 1)
const String kGoogleWebClientId = '559229937063-sp4cfdk9dn3uano0g84f6ei502j7tvh7.apps.googleusercontent.com';

// ============================================================================
// Auth Domain Event Types
// ============================================================================

/// Domain events emitted by AuthRepository to the auth provider.
/// These are app-level events, not Google SDK types.
sealed class AuthEvent {
  const AuthEvent();
}

class AuthEventSignedIn extends AuthEvent {
  final String googleId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String idToken;

  const AuthEventSignedIn({
    required this.googleId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.idToken,
  });
}

class AuthEventSignedOut extends AuthEvent {
  const AuthEventSignedOut();
}

class AuthEventError extends AuthEvent {
  final Object error;
  const AuthEventError(this.error);
}

// ============================================================================
// AuthRepository
// ============================================================================

/// Wraps google_sign_in v7 with the event-stream API.
///
/// Key v7 changes from v6:
/// - Use authenticate() instead of signIn() (removed in v7)
/// - Use attemptLightweightAuthentication() instead of signInSilently() (removed in v7)
/// - user.authentication.idToken is synchronous (no await needed)
/// - initialize() must complete before authenticate() or attemptLightweightAuthentication()
///
/// See: .planning/phases/01-foundation-and-auth/01-RESEARCH.md (Pattern 2)
class AuthRepository {
  final _signIn = GoogleSignIn.instance;
  final _authEventController = StreamController<AuthEvent>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  /// Stream of domain auth events (sign-in, sign-out, error).
  /// The auth provider listens to this to update app state.
  Stream<AuthEvent> get authEvents => _authEventController.stream;

  /// The current Google ID token, kept for Convex's fetchToken callback.
  /// Set on sign-in, cleared on sign-out.
  String? _currentIdToken;

  /// Returns the most recently retrieved Google ID token, or null.
  /// Used by ConvexService's fetchToken callback for silent refresh.
  String? get currentIdToken => _currentIdToken;

  /// Initializes Google Sign-In and subscribes to authentication events.
  ///
  /// MUST be called and awaited before signIn() or attemptSilentSignIn().
  /// Called by AuthNotifier.build() which is awaited by Riverpod.
  ///
  /// Per Pitfall 4: initialize() race condition — do NOT call authenticate()
  /// until this future completes.
  Future<void> initialize() async {
    // Initialize with the Web Client ID so Android gets a valid idToken
    // (Pitfall 1: missing serverClientId causes null idToken on Android)
    await _signIn.initialize(
      serverClientId: kGoogleWebClientId,
      // No scopes here — Calendar scope added separately in Plan 04 (Pitfall 5)
    );

    // Subscribe to auth events BEFORE attempting lightweight auth
    // so we don't miss any sign-in event that fires immediately
    _subscription = _signIn.authenticationEvents.listen(
      _onAuthEvent,
      onError: (Object error) {
        _currentIdToken = null;
        _authEventController.add(AuthEventError(error));
      },
    );

    // Attempt silent sign-in to restore session from previous app run
    // Returns a Future<GoogleSignInAccount?>? (note the nullable Future)
    // If null is returned, results come via the event stream only
    final future = _signIn.attemptLightweightAuthentication();
    // If a Future is returned, we await it for fast session restore.
    // If null is returned (e.g. FedCM on web), we rely on the stream.
    if (future != null) {
      try {
        await future;
      } on GoogleSignInException {
        // No cached credential — expected on fresh install or expired session.
        // The auth event stream error handler will emit AuthEventError,
        // and AuthNotifier will set state to unauthenticated.
      }
    }
  }

  /// Triggers the interactive Google sign-in flow.
  ///
  /// Only call on platforms where supportsAuthenticate() is true.
  /// Result arrives via the authEvents stream (AuthEventSignedIn).
  Future<void> signIn() async {
    if (!_signIn.supportsAuthenticate()) {
      _authEventController.add(
        AuthEventError(UnsupportedError(
          'Interactive sign-in is not supported on this platform.',
        )),
      );
      return;
    }
    try {
      // authenticate() result also fires via authenticationEvents stream,
      // but we await here so errors surface immediately
      await _signIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User cancelled — not an error, just ignore
        return;
      }
      _authEventController.add(AuthEventError(e));
    } catch (e) {
      _authEventController.add(AuthEventError(e));
    }
  }

  /// Signs out of Google and clears the cached ID token.
  Future<void> signOut() async {
    _currentIdToken = null;
    await _signIn.signOut();
    // signOut() fires a GoogleSignInAuthenticationEventSignOut on the stream,
    // which we handle in _onAuthEvent to emit AuthEventSignedOut
  }

  /// Attempts a silent re-authentication (no user interaction).
  ///
  /// Used by ConvexService's fetchToken callback to get a fresh ID token
  /// before the current one expires. Returns the new ID token or null.
  ///
  /// Per Pitfall 3: this is the silent refresh mechanism for Convex's
  /// setAuthWithRefresh, which calls fetchToken 60s before token expiry.
  Future<String?> attemptSilentSignIn() async {
    try {
      final future = _signIn.attemptLightweightAuthentication();
      if (future == null) {
        // Platform-specific behavior: no immediate result available
        return _currentIdToken;
      }
      final account = await future;
      if (account == null) return null;
      final token = account.authentication.idToken;
      if (token != null) {
        _currentIdToken = token;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        final user = event.user;
        final idToken = user.authentication.idToken; // Synchronous in v7

        if (idToken == null) {
          // Should not happen if serverClientId is correctly configured.
          // If it does, log and treat as an error.
          _authEventController.add(
            AuthEventError(
              StateError(
                'Google ID token is null. '
                'Verify serverClientId is the Web OAuth 2.0 Client ID '
                '(not iOS or Android). See auth_repository.dart kGoogleWebClientId.',
              ),
            ),
          );
          return;
        }

        _currentIdToken = idToken;
        _authEventController.add(
          AuthEventSignedIn(
            googleId: user.id,
            email: user.email,
            displayName: user.displayName ?? user.email,
            avatarUrl: user.photoUrl,
            idToken: idToken,
          ),
        );

      case GoogleSignInAuthenticationEventSignOut():
        _currentIdToken = null;
        _authEventController.add(const AuthEventSignedOut());
    }
  }

  void dispose() {
    _subscription?.cancel();
    _authEventController.close();
  }
}

// ============================================================================
// Riverpod Provider
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
