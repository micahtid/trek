// Auth domain state — sealed class pattern.
//
// All auth consumers depend on this sealed class, not on Google or Convex internals.
// The router and UI watch the provider that emits these states.

sealed class AuthState {
  const AuthState();
}

/// User is not signed in. Sign-in screen should be shown.
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Auth operation in progress (initial check or sign-in attempt).
/// Router does not redirect while loading, to avoid flicker.
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is signed in. Convex user ID and profile info are available.
class AuthStateAuthenticated extends AuthState {
  /// Convex document _id for this user (returned by upsertUser mutation).
  final String userId;

  /// User's Google email address.
  final String email;

  /// User's display name from Google profile.
  final String displayName;

  /// User's Google profile photo URL, or null if not set.
  final String? avatarUrl;

  const AuthStateAuthenticated({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });
}
