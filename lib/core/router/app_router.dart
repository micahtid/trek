import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/today/today_screen.dart';
import '../../features/vault/vault_screen.dart';
import '../../features/settings/settings_screen.dart';

/// A [ChangeNotifier] that bridges Riverpod provider observation to
/// go_router's [refreshListenable] contract.
///
/// go_router calls [addListener] on the refreshListenable; when auth
/// state changes, [notifyListeners] fires, causing the router to
/// re-evaluate its redirect callback.
class _RiverpodRefreshListenable extends ChangeNotifier {
  _RiverpodRefreshListenable(Ref ref) {
    _subscription = ref.listen<AsyncValue<AuthState>>(
      authNotifierProvider,
      (prev, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Router provider — uses [Ref] so the router can watch auth state.
///
/// The router:
/// - Has a `/sign-in` route OUTSIDE the ShellRoute (no bottom nav on sign-in)
/// - Has a [redirect] guard that redirects unauthenticated users to /sign-in
/// - Has [refreshListenable] so it reacts to auth state changes instantly
final routerProvider = Provider<GoRouter>((ref) {
  // Create a refreshListenable that triggers on any auth state change
  final authListenable = _RiverpodRefreshListenable(ref);

  // Ensure the listenable is disposed when this provider is disposed
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/today',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final authState = authAsync.asData?.value;
      final isLoading = authAsync.isLoading || authState is AuthStateLoading;
      final isAuthenticated = authState is AuthStateAuthenticated;
      final onSignIn = state.matchedLocation == '/sign-in';

      // Don't redirect while auth is still loading (prevents flicker)
      if (isLoading) return null;

      // Unauthenticated and not already on sign-in → go to sign-in
      if (!isAuthenticated && !onSignIn) return '/sign-in';

      // Authenticated and on sign-in → go to Today tab (per user decision)
      if (isAuthenticated && onSignIn) return '/today';

      return null;
    },
    routes: [
      // Sign-in route — outside ShellRoute, no bottom navigation
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignInScreen(),
        ),
      ),
      // App shell with bottom navigation tabs
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) {
              final eventId = state.uri.queryParameters['eventId'];
              return NoTransitionPage(
                child: TodayScreen(highlightEventId: eventId),
              );
            },
          ),
          GoRoute(
            path: '/vault',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VaultScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
