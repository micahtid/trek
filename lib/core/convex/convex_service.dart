import 'package:convex_flutter/convex_flutter.dart';

// ============================================================================
// Convex Configuration
// ============================================================================

/// Convex deployment URL.
///
/// Created by `npx convex dev --once --configure=new` in Plan 01.
/// Project: intern-growth-vault, Team: micah
///
/// See: .planning/phases/01-foundation-and-auth/01-01-SUMMARY.md
const String kConvexDeploymentUrl = 'https://grand-tortoise-682.convex.cloud';

// ============================================================================
// Convex Client Initialization
// ============================================================================

/// Initializes the ConvexClient singleton.
///
/// Called from main() before runApp() to ensure the client is ready
/// before any Riverpod providers attempt to use it.
///
/// The auth bridge (setAuthWithRefresh) is set up separately by ConvexService
/// after the AuthRepository is initialized.
Future<void> initConvexClient() async {
  await ConvexClient.initialize(
    const ConvexConfig(
      deploymentUrl: kConvexDeploymentUrl,
      clientId: 'intern-growth-vault-flutter',
    ),
  );
}

// ============================================================================
// ConvexService — Auth Bridge
// ============================================================================

/// Manages the Convex auth bridge (setAuthWithRefresh).
///
/// This wires google_sign_in's silent re-auth to Convex's token refresh loop.
/// Convex calls fetchToken:
/// - On startup (to restore session)
/// - 60 seconds before token expiry (to prevent session expiry)
///
/// See: .planning/phases/01-foundation-and-auth/01-RESEARCH.md (Pattern 1, Pitfall 3)
class ConvexService {
  ConvexService._();

  static final ConvexService instance = ConvexService._();

  AuthHandleWrapper? _authHandle;

  /// Sets up the Convex auth bridge with a token fetch callback.
  ///
  /// [fetchToken] is called by Convex on startup and before token expiry.
  /// It should attempt silent Google sign-in and return the ID token, or
  /// null to signal the user is signed out.
  ///
  /// [onAuthChange] is called when Convex's auth state changes (true = authenticated).
  Future<void> setupAuth({
    required Future<String?> Function() fetchToken,
    void Function(bool isAuthenticated)? onAuthChange,
  }) async {
    _authHandle?.dispose();
    _authHandle = await ConvexClient.instance.setAuthWithRefresh(
      fetchToken: fetchToken,
      onAuthChange: onAuthChange,
    );
  }

  /// Clears the Convex auth session (called on sign-out).
  Future<void> clearAuth() async {
    _authHandle?.dispose();
    _authHandle = null;
    await ConvexClient.instance.clearAuth();
  }

  /// Whether Convex considers the user authenticated.
  bool get isAuthenticated => _authHandle?.isAuthenticated ?? false;

  /// Stream of Convex auth state changes.
  Stream<bool> get authState => ConvexClient.instance.authState;

  /// Executes a Convex mutation.
  Future<String> mutation({
    required String name,
    required Map<String, dynamic> args,
  }) {
    return ConvexClient.instance.mutation(name: name, args: args);
  }

  /// Executes a Convex query.
  Future<String> query(String name, Map<String, dynamic> args) {
    return ConvexClient.instance.query(name, args);
  }
}
