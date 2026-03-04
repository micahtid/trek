# Phase 1: Foundation and Auth - Research

**Researched:** 2026-03-02
**Domain:** Flutter mobile auth (Google OAuth + Convex OIDC bridge), app shell, navigation
**Confidence:** MEDIUM — Core patterns verified via official docs and pub.dev; the Convex-Flutter OIDC bridge is underdocumented and rated LOW confidence for its specific implementation details

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Sign-in experience:** Minimal + bold: logo, tagline, single "Sign in with Google" button. No onboarding screens, no value pitch — confident and clean.
- **Tagline:** Claude's discretion (something fitting for the "growth vault" brand)
- **Visual design:** Light + clean aesthetic: white/light gray backgrounds, modern feel
- **Primary font:** Sora (Google Font) — use throughout the app
- **Primary accent color:** Amber/gold — ties to the "vault" concept
- **Onboarding flow:** Straight to canvas after first Google sign-in — no setup wizard, no guided tour
- **After auth landing screen:** Today tab (daily canvas)
- **Integration linking:** Both Calendar and GitHub connections live in Settings only — not prompted during onboarding
- **App shell navigation:** Bottom navigation tabs: Today / Vault / Settings
- **Today tab:** Daily canvas (default landing screen)
- **Vault tab:** Permanent vault / search
- **Settings tab:** Profile, Calendar connection, GitHub connection, account management

### Claude's Discretion
- Specific tagline copy for sign-in screen
- Spacing, icon choices, and layout details
- Loading states and transitions
- Error state handling (token expiry, network issues)
- Exact bottom nav icon choices and tab naming
- Modern aesthetic research to inform design system decisions

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | User can sign up and sign in with Google OAuth | `google_sign_in` v7.2.0 via `authenticate()` + event stream; Convex custom OIDC config with Google as provider |
| AUTH-02 | User session persists across app restarts (Convex auth token refresh) | `convex_flutter` v3.0.1 `setAuthWithRefresh` with `fetchToken` callback; `google_sign_in` v7 `attemptLightweightAuthentication()` for silent restore |
| AUTH-03 | User can optionally grant Google Calendar read permission (incremental scope) | `google_sign_in` v7 `authorizeScopes()` called from Settings — separate from sign-in; scope: `https://www.googleapis.com/auth/calendar.readonly` |
| AUTH-04 | User can optionally connect a GitHub account for commit tracking | `oauth2_client` v4.2.3 `GitHubOAuth2Client` with `OAuth2Helper`; settings-only flow; token stored in `flutter_secure_storage` |
</phase_requirements>

---

## Summary

Phase 1 establishes three distinct systems: (1) Google sign-in via `google_sign_in` v7, (2) a custom OIDC bridge connecting Google ID tokens to Convex's auth system, and (3) the Flutter app shell (Material 3, Sora font, amber theme, bottom nav, go_router guards). The most technically risky piece is the Convex-Flutter OIDC bridge — Convex's official auth library has no Flutter support, so the project must use the custom OIDC path in `convex/auth.config.ts` and wire it to `convex_flutter`'s `setAuthWithRefresh` using Google ID tokens. This bridge is flagged as underdocumented in STATE.md and confirmed by research.

The second key risk is token refresh: Google ID tokens expire after 1 hour. `google_sign_in` v7 has no built-in refresh token mechanism, but `attemptLightweightAuthentication()` performs a silent re-auth that yields a fresh ID token when the user is still signed into Google on the device. The `setAuthWithRefresh` `fetchToken` callback is the right hook to trigger this silent re-auth and return a fresh token to Convex before the session expires.

GitHub auth (AUTH-04) is lower risk — it's an OAuth 2.0 Authorization Code flow handled by `oauth2_client` with a pre-built `GitHubOAuth2Client`, stored securely and accessed only from Settings. Google Calendar incremental scope (AUTH-03) is also well-understood: call `authorizeScopes()` from Settings with the `calendar.readonly` scope, separate from the primary sign-in flow.

**Primary recommendation:** Build the Convex OIDC bridge first as an isolated prototype before touching UI. The bridge is the load-bearing piece everything else depends on. If it breaks, nothing else works.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `google_sign_in` | 7.2.0 | Google OAuth sign-in, ID token retrieval | Official Flutter/Google package; v7 is current stable with new event-stream API |
| `convex_flutter` | 3.0.1 | Convex backend client — queries, mutations, subscriptions, auth | Official Convex Flutter SDK; 7 days old as of research; `setAuthWithRefresh` is the token bridge |
| `go_router` | 17.1.0 | Declarative routing with auth guards and redirect | flutter.dev maintained; `redirect` callback reacts to auth state; works with Riverpod |
| `riverpod` | 3.2.1 | Auth state management and dependency injection | Modern gold standard for Flutter; less boilerplate than BLoC; `AsyncNotifier` pattern for auth |
| `google_fonts` | 8.0.2 | Sora font (and any future Google Font additions) | Official Google Fonts package; `GoogleFonts.soraTextTheme()` applies to entire MaterialApp |
| `flutter_secure_storage` | 10.0.0 | Encrypted token storage (GitHub OAuth token) | Uses Keychain (iOS) and RSA OAEP + AES-GCM (Android); minimum API 23 |
| `oauth2_client` | 4.2.3 | GitHub OAuth 2.0 Authorization Code flow | Has pre-built `GitHubOAuth2Client`; handles token storage and refresh automatically |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_web_auth_2` | (peer dep) | Browser-based OAuth callback handling | Required by `oauth2_client` for GitHub redirect; handles custom URI scheme callbacks on Android/iOS |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `riverpod` | `bloc` | BLoC has more boilerplate and is better suited for large enterprise teams; Riverpod is the modern standard for a solo/small-team project of this size |
| `oauth2_client` | `flutter_appauth` | `flutter_appauth` is more generic OIDC-focused; `oauth2_client` has a `GitHubOAuth2Client` built-in that saves setup time |
| `go_router` | `auto_route` | `auto_route` uses code generation; `go_router` is flutter.dev's own package with simpler setup for this project's navigation depth |

**Installation:**
```bash
flutter pub add google_sign_in convex_flutter go_router riverpod flutter_riverpod google_fonts flutter_secure_storage oauth2_client
```

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── main.dart                   # Entry point — initializes Convex, Riverpod, router
├── app.dart                    # MaterialApp.router with theme, font, color scheme
├── core/
│   ├── theme/
│   │   └── app_theme.dart      # ThemeData: Sora font, amber ColorScheme.fromSeed
│   ├── router/
│   │   └── app_router.dart     # go_router definition with auth redirect guard
│   └── convex/
│       └── convex_service.dart # ConvexClient singleton init, setAuthWithRefresh wiring
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart  # google_sign_in calls, ID token retrieval, sign-out
│   │   ├── domain/
│   │   │   └── auth_state.dart       # Sealed class: unauthenticated | loading | authenticated
│   │   └── presentation/
│   │       ├── auth_provider.dart    # Riverpod AsyncNotifier — drives auth state
│   │       └── sign_in_screen.dart   # Minimal sign-in UI: logo + tagline + Google button
│   ├── shell/
│   │   └── app_shell.dart      # Scaffold with NavigationBar (Today / Vault / Settings tabs)
│   ├── today/
│   │   └── today_screen.dart   # Placeholder for Phase 2
│   ├── vault/
│   │   └── vault_screen.dart   # Placeholder for Phase 6
│   └── settings/
│       ├── settings_screen.dart        # Profile, sign-out, Calendar link, GitHub link
│       ├── calendar_auth_section.dart  # Incremental scope grant for Calendar
│       └── github_auth_section.dart    # GitHub OAuth flow trigger and status
convex/
├── auth.config.ts              # Custom OIDC config: Google as provider
└── schema.ts                   # users table with userId, email, name, avatarUrl
```

### Pattern 1: Convex OIDC Bridge (THE critical pattern)

**What:** Google ID tokens are JWTs issued by Google at `https://accounts.google.com`. Convex can be configured to trust them via `auth.config.ts` custom OIDC. On the Flutter side, `setAuthWithRefresh` receives a `fetchToken` callback that returns a fresh Google ID token. Convex's client calls this callback 60 seconds before the token expires, triggering a silent re-auth via `attemptLightweightAuthentication()`.

**When to use:** This is the only supported path for Convex + Flutter auth. Convex Auth (the React library) has no Flutter SDK.

**Convex backend config:**
```typescript
// Source: https://docs.convex.dev/auth/advanced/custom-auth
// convex/auth.config.ts
import { AuthConfig } from "convex/server";

export default {
  providers: [
    {
      domain: "https://accounts.google.com",
      applicationID: "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
      // applicationID MUST match the `aud` claim in the Google ID token.
      // Use the Web OAuth 2.0 client ID from Google Cloud Console — NOT the iOS or Android client ID.
    },
  ],
} satisfies AuthConfig;
```

**Flutter auth bridge:**
```dart
// Source: convex_flutter 3.0.1 README + google_sign_in v7 example
// core/convex/convex_service.dart

Future<void> initConvexAuth() async {
  final client = ConvexClient.instance;

  await client.setAuthWithRefresh(
    fetchToken: () async {
      // Convex calls this 60s before token expires and on startup
      // Attempt silent re-auth to get a fresh ID token
      final signIn = GoogleSignIn.instance;

      // Try lightweight (silent) authentication first
      // This uses cached credentials — no user interaction
      final user = await _tryLightweightAuth(signIn);
      if (user == null) return null; // User is signed out

      final auth = user.authentication;
      return auth.idToken; // Fresh ID token, valid for 1 hour
    },
    onAuthChange: (isAuthenticated) {
      // Notify Riverpod auth provider to update UI
      authStateNotifier.updateFromConvex(isAuthenticated);
    },
  );
}
```

**IMPORTANT:** The `applicationID` in `auth.config.ts` must be the **Web OAuth 2.0 Client ID**, not the iOS or Android client ID. The `serverClientId` in `google_sign_in` initialization must match this same web client ID. This is required for the `aud` claim in the JWT to match Convex's configured `applicationID`.

### Pattern 2: Google Sign-In v7 Event Stream

**What:** v7 replaced the future-based sign-in API with an event stream. Initialization is async and must complete before showing auth UI. `authenticate()` triggers the Google sign-in sheet. The `authenticationEvents` stream emits sign-in/sign-out events.

**When to use:** All Google sign-in operations in this project.

```dart
// Source: https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/example/lib/main.dart
// features/auth/data/auth_repository.dart

class AuthRepository {
  final _signIn = GoogleSignIn.instance;

  Future<void> initialize() async {
    await _signIn.initialize(
      // clientId: iOS client ID (required on iOS)
      serverClientId: 'WEB_CLIENT_ID.apps.googleusercontent.com', // Required on Android for idToken
    );

    // Start listening to auth events BEFORE attempting lightweight auth
    _signIn.authenticationEvents
      .listen(_onAuthEvent)
      .onError(_onAuthError);

    // Try silent sign-in on startup (replaces v6 signInSilently)
    _signIn.attemptLightweightAuthentication();
  }

  Future<void> signIn() async {
    // Only supported on platforms where supportsAuthenticate() is true
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      await _signIn.authenticate();
    }
  }

  Future<void> signOut() async {
    await _signIn.signOut();
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        final user = event.user;
        final idToken = user.authentication.idToken; // Synchronous in v7
        // Notify auth provider with user + token
      case GoogleSignInAuthenticationEventSignOut():
        // Clear user state
    }
  }
}
```

### Pattern 3: Riverpod Auth State

**What:** `AsyncNotifier` manages the auth lifecycle. go_router's `redirect` listens to this provider and redirects to `/sign-in` when unauthenticated.

```dart
// Source: riverpod.dev pattern docs
// features/auth/presentation/auth_provider.dart

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    // Initialize on first build — waits for lightweight auth attempt
    await ref.read(authRepositoryProvider).initialize();
    return AuthState.unauthenticated();
  }
}

// core/router/app_router.dart
final router = GoRouter(
  routes: [...],
  redirect: (context, state) {
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
    final isLoading = authState.isLoading;

    if (isLoading) return null; // Don't redirect while loading
    if (!isAuthenticated && state.matchedLocation != '/sign-in') return '/sign-in';
    if (isAuthenticated && state.matchedLocation == '/sign-in') return '/today';
    return null;
  },
  refreshListenable: ..., // Notify router on auth state changes
);
```

### Pattern 4: Material 3 Theme with Sora + Amber

```dart
// Source: google_fonts 8.0.2 README, Flutter Material 3 docs
// core/theme/app_theme.dart

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC107), // amber[500]
      brightness: Brightness.light,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.soraTextTheme(base.textTheme),
  );
}
```

### Pattern 5: Bottom Navigation Shell

```dart
// Source: Flutter Material 3 NavigationBar API docs
// features/shell/app_shell.dart

class AppShell extends StatefulWidget {
  final Widget child; // go_router provides this via ShellRoute

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => _onTabTapped(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.lock_outlined), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
```

### Anti-Patterns to Avoid

- **Storing ID tokens in SharedPreferences:** Google ID tokens are bearer tokens. Use `flutter_secure_storage` for GitHub tokens; let `google_sign_in` manage its own token caching.
- **Requesting Calendar scope at sign-in:** This is explicitly against Google's incremental authorization best practice and the user decision. Request it from Settings only.
- **Using `signIn()` / `signInSilently()` (v6 API):** These are removed in v7. Use `authenticate()` and `attemptLightweightAuthentication()`.
- **Using `BottomNavigationBar`:** This is the legacy Material 2 widget. Use `NavigationBar` for Material 3.
- **Using iOS client ID as `serverClientId`:** The `serverClientId` must be the Web OAuth 2.0 client ID; using iOS client ID causes idToken to be null on Android.
- **Using Android client ID as `applicationID` in Convex:** The `aud` claim in the JWT will match the Web client ID, not the Android client ID.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token storage | Custom encrypted storage | `flutter_secure_storage` 10.0.0 | Platform Keychain/Keystore integration is non-trivial; handles all edge cases |
| GitHub OAuth flow | Custom web view or URL launcher + manual token exchange | `oauth2_client` GitHubOAuth2Client | Handles PKCE, redirect URI callback, token storage, automatic refresh |
| Google sign-in UI | Custom "Sign in with Google" button | `google_sign_in`'s `authenticate()` + standard button | Google's brand guidelines require specific button styling; custom implementations risk policy violation |
| Bottom nav routing | Custom Navigator.push-based tab switching | `go_router` ShellRoute | Deep linking, back-button handling, state restoration are all handled; manual tab nav breaks deep links |
| Auth state propagation | Global boolean variable | Riverpod `AsyncNotifier` + go_router `refreshListenable` | Race conditions between router rebuild and auth state are eliminated by the Listenable pattern |
| Convex OIDC token verification | Custom JWT parsing in Flutter | Convex backend `auth.config.ts` | Token signature verification must happen server-side; client-side JWT parsing is a security anti-pattern |

**Key insight:** The auth stack in this phase has multiple pieces that interact in non-obvious ways (client IDs, token audiences, silent re-auth). Every one of these libraries was built specifically to handle these edge cases. Custom implementations reliably fail at the edge cases.

---

## Common Pitfalls

### Pitfall 1: Google ID Token is null on Android

**What goes wrong:** `user.authentication.idToken` returns `null` at runtime.
**Why it happens:** The `serverClientId` parameter was not set, or was set to the wrong client ID (iOS or Android instead of Web). The Google sign-in SDK on Android only includes the `aud` claim (and thus populates `idToken`) when it knows the intended server audience.
**How to avoid:** Create a Web OAuth 2.0 client ID in Google Cloud Console (even if the app is mobile-only). Pass this Web client ID as `serverClientId` in `GoogleSignIn.instance.initialize()`. This same Web client ID goes in `applicationID` in Convex's `auth.config.ts`.
**Warning signs:** `idToken` is non-null on iOS but null on Android — classic missing `serverClientId` signature.

### Pitfall 2: Convex auth.config.ts applicationID mismatch

**What goes wrong:** Convex rejects auth with a 401 even though sign-in succeeded client-side.
**Why it happens:** The `aud` claim in a Google ID token contains the OAuth client ID that the token was issued for. If `applicationID` in `auth.config.ts` doesn't match this exactly, Convex rejects the token as not intended for this application.
**How to avoid:** Use `jwt.io` to decode a real ID token from a sign-in flow and verify the `aud` and `iss` fields before setting the config. `iss` will be `https://accounts.google.com`. `aud` will be the Web client ID.
**Warning signs:** Sign-in succeeds on the Flutter side but Convex queries fail with auth errors immediately after.

### Pitfall 3: Token refresh gap — user gets logged out after 1 hour

**What goes wrong:** After an hour of app use, Convex stops accepting requests because the Google ID token expired and wasn't refreshed.
**Why it happens:** Google ID tokens expire after 3600 seconds. Unlike Firebase Auth, `google_sign_in` v7 has no automatic refresh token mechanism.
**How to avoid:** The `setAuthWithRefresh` `fetchToken` callback is called by Convex 60 seconds before expiry. Inside this callback, call `attemptLightweightAuthentication()` to get a fresh ID token silently (no user interaction if the user's Google session is still active on-device). This is the only supported silent refresh path.
**Warning signs:** Auth works for the first hour, then users get redirected to sign-in without signing out.

### Pitfall 4: google_sign_in v7 initialization race condition

**What goes wrong:** Calling `authenticate()` before `initialize()` completes throws an exception.
**Why it happens:** v7 requires async initialization. `initialize()` must complete before `authenticationEvents` can be listened to or `authenticate()` can be called.
**How to avoid:** `await _signIn.initialize()` before setting up the event listener or calling `attemptLightweightAuthentication()`. Do this in `AuthRepository.initialize()` which is awaited by the Riverpod notifier's `build()` method.
**Warning signs:** Crash or unhandled exception on cold app start, especially on first install.

### Pitfall 5: Calendar scope requested alongside sign-in

**What goes wrong:** User is prompted to grant Calendar access during the Google sign-in flow, creating friction and confusion.
**Why it happens:** Calendar scope accidentally included in the `scopes` list during `GoogleSignIn.instance.initialize()`.
**How to avoid:** Initialize with an empty scopes list (or `openid` only). Calendar scope is requested separately via `authorizeScopes(['https://www.googleapis.com/auth/calendar.readonly'])` when the user taps the Calendar connection button in Settings.
**Warning signs:** Google's consent screen during sign-in shows calendar access in the permissions list.

### Pitfall 6: GitHub OAuth breaks Google session

**What goes wrong:** After GitHub OAuth flow, Google sign-in state is disrupted or the user appears signed out of Google.
**Why it happens:** `oauth2_client` opens a system browser for the GitHub OAuth redirect. If not properly isolated from Google's auth, the browser session can interfere. (Less common, but noted as a concern in STATE.md.)
**How to avoid:** GitHub OAuth uses `oauth2_client` which is completely independent of `google_sign_in`. They operate through different mechanisms (custom URI scheme redirect vs Google's native SDK). The isolation is structural. Verify by testing GitHub OAuth while Google is signed in.
**Warning signs:** User returns from GitHub OAuth flow and finds themselves on the sign-in screen.

---

## Code Examples

Verified patterns from official sources:

### Convex backend auth.config.ts (complete)
```typescript
// Source: https://docs.convex.dev/auth/advanced/custom-auth
import { AuthConfig } from "convex/server";

export default {
  providers: [
    {
      domain: "https://accounts.google.com",
      // iss claim in Google ID tokens is always this value
      applicationID: "123456789-abcdefg.apps.googleusercontent.com",
      // aud claim in Google ID tokens = the Web OAuth 2.0 Client ID
      // Get this from Google Cloud Console > APIs & Services > Credentials > Web client
    },
  ],
} satisfies AuthConfig;
```

### convex_flutter setAuthWithRefresh (complete pattern)
```dart
// Source: convex_flutter 3.0.1 pub.dev README
final authHandle = await client.setAuthWithRefresh(
  fetchToken: () async {
    // Called: on startup, and 60s before token expiry
    // Must return a valid JWT or null (null = sign out from Convex's perspective)
    final user = await _getSilentUser(); // attemptLightweightAuthentication() wrapper
    if (user == null) return null;
    return user.authentication.idToken;
  },
  onAuthChange: (isAuthenticated) {
    // React to Convex's auth state — update Riverpod
  },
);
```

### google_sign_in v7 initialization + event stream
```dart
// Source: https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/example/lib/main.dart
await GoogleSignIn.instance.initialize(
  // clientId: 'iOS_CLIENT_ID.apps.googleusercontent.com', // iOS only
  serverClientId: 'WEB_CLIENT_ID.apps.googleusercontent.com', // Required for idToken on Android
);
GoogleSignIn.instance.authenticationEvents
  .listen((event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        final idToken = event.user.authentication.idToken; // Synchronous in v7
      case GoogleSignInAuthenticationEventSignOut():
        // handle sign-out
    }
  });
GoogleSignIn.instance.attemptLightweightAuthentication(); // Triggers silent sign-in if previously authenticated
```

### Sora font app-wide theme
```dart
// Source: google_fonts 8.0.2 pub.dev README
ThemeData _buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC107), // Colors.amber[500]
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.soraTextTheme(base.textTheme),
  );
}
```

### GitHub OAuth via oauth2_client
```dart
// Source: oauth2_client 4.2.3 pub.dev README
import 'package:oauth2_client/github_oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

final ghClient = GitHubOAuth2Client(
  redirectUri: 'com.yourapp.interngrowthvault://oauth2redirect',
  customUriScheme: 'com.yourapp.interngrowthvault',
);
final helper = OAuth2Helper(
  ghClient,
  grantType: OAuth2Helper.authorizationCode,
  clientId: 'YOUR_GITHUB_CLIENT_ID',
  clientSecret: 'YOUR_GITHUB_CLIENT_SECRET',
  scopes: ['read:user', 'repo'], // read:user for identity, repo for commit access
);
// Call from Settings — this opens a browser for user to authorize
final response = await helper.get('https://api.github.com/user');
```

### go_router with auth guard
```dart
// Source: https://pub.dev/packages/go_router (Redirection docs)
final router = GoRouter(
  initialLocation: '/today',
  redirect: (BuildContext context, GoRouterState state) {
    final authState = ProviderScope.containerOf(context).read(authNotifierProvider);
    final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
    final isLoading = authState.isLoading;

    if (isLoading) return null;

    final onSignIn = state.matchedLocation == '/sign-in';
    if (!isAuthenticated && !onSignIn) return '/sign-in';
    if (isAuthenticated && onSignIn) return '/today';
    return null;
  },
  routes: [
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
        GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `signInSilently()` | `attemptLightweightAuthentication()` | google_sign_in v7.0 (2024) | Old API removed; must migrate or crash |
| `await googleUser.authentication` (async) | `user.authentication` (synchronous) | google_sign_in v7.0 (2024) | No await needed; calling await still works but is not idiomatic |
| `signIn()` future | `authenticate()` + `authenticationEvents` stream | google_sign_in v7.0 (2024) | Event-driven model replaces promise-based |
| `BottomNavigationBar` | `NavigationBar` | Flutter Material 3 (now default) | Legacy widget still works but is the M2 pattern |
| `ThemeData(primarySwatch:)` | `ThemeData(colorScheme: ColorScheme.fromSeed())` | Flutter 3.x Material 3 | Old constructor still works but M3 uses seed colors |
| `google_generative_ai` package | `firebase_ai ^3.8.0` | 2024/2025 | `google_generative_ai` is deprecated per STATE.md — do not use in this project |
| Convex Auth (React library) | Custom OIDC via `auth.config.ts` | N/A — Flutter never supported | There is no Convex Auth Flutter SDK; custom OIDC is the only supported path |

**Deprecated/outdated:**
- `google_generative_ai`: Deprecated — use `firebase_ai ^3.8.0` (from STATE.md pre-phase decision)
- `BottomNavigationBar`: Use `NavigationBar` for Material 3 projects
- `GoogleSignIn()` constructor with `scopes` parameter: v7 changed the initialization and scoping API significantly

---

## Open Questions

1. **How does `attemptLightweightAuthentication()` behave when the user's Google session has expired on-device?**
   - What we know: It triggers a silent sign-in attempt; if successful, emits a `GoogleSignInAuthenticationEventSignIn` event
   - What's unclear: If the on-device Google session has expired (e.g., after password change), does it silently fail or emit an error event? The `fetchToken` callback returning `null` should cause Convex to sign the user out — but will they see a sign-in prompt or just get redirected?
   - Recommendation: Test this edge case explicitly during Phase 1 development. Ensure error handling in the auth event listener triggers navigation to sign-in screen with a clear UX message.

2. **Does Convex's custom OIDC accept Google ID tokens that use the Web client ID as `aud`?**
   - What we know: Google's OIDC endpoints are at `https://accounts.google.com/.well-known/openid-configuration` and `https://accounts.google.com/.well-known/jwks.json` — Convex's requirements are met. The `iss` claim will be `https://accounts.google.com`. The `aud` claim will be the Web client ID.
   - What's unclear: Whether Convex has any additional requirements or quirks for Google specifically that aren't in the docs. The STATE.md explicitly flags this as underdocumented.
   - Recommendation: Build the Convex OIDC bridge as the first task of Phase 1. Use a minimal test harness — sign in, get ID token, call a Convex query — before building any UI.

3. **What Google Cloud Console OAuth client setup is required?**
   - What we know: Need at least: (1) a Web OAuth 2.0 client ID (for `serverClientId` + Convex `applicationID`), (2) an iOS OAuth client ID, (3) possibly an Android OAuth client ID (though the Web client ID covers the `serverClientId` need).
   - What's unclear: Whether the iOS and Android client IDs need to be separately created in Google Cloud Console for `google_sign_in` v7, or if the Web client ID alone is sufficient.
   - Recommendation: Follow the standard Firebase setup path (even without Firebase auth) to ensure all required client IDs and SHA-1 fingerprints are configured. Then bypass Firebase Auth and use ID tokens directly.

4. **GitHub OAuth: which scopes are needed for Phase 1?**
   - What we know: `read:user` is needed to get the user's GitHub identity. `repo` scope gives access to commits and PR descriptions (needed in Phase 5 for INTG-03).
   - What's unclear: Whether to request `repo` scope upfront in Phase 1 (when the user connects GitHub) or defer to Phase 5 (when commit access is actually needed).
   - Recommendation: Request only `read:user` in Phase 1 to minimize scope friction. Add `repo` scope in Phase 5 when it's actually needed (incremental authorization pattern — same as Calendar).

---

## Sources

### Primary (HIGH confidence)
- `convex_flutter` pub.dev (v3.0.1) — `ConvexClient.initialize()`, `setAuthWithRefresh`, `authState` stream API
- `google_sign_in` pub.dev (v7.2.0) — v7 API: `initialize()`, `authenticate()`, `attemptLightweightAuthentication()`, `authenticationEvents`
- `google_fonts` pub.dev (v8.0.2) — `GoogleFonts.soraTextTheme()` pattern
- `flutter_secure_storage` pub.dev (v10.0.0) — encrypted storage on iOS Keychain and Android Keystore
- `oauth2_client` pub.dev (v4.2.3) — `GitHubOAuth2Client`, `OAuth2Helper`
- `go_router` pub.dev (v17.1.0) — `redirect` callback, `ShellRoute`
- `riverpod` pub.dev (v3.2.1) — `AsyncNotifier` pattern
- https://docs.convex.dev/auth/advanced/custom-auth — `domain` and `applicationID` fields, JWKS endpoint requirements
- https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/example/lib/main.dart — official v7 example code

### Secondary (MEDIUM confidence)
- https://developers.google.com/workspace/calendar/api/auth — `calendar.readonly` scope, incremental authorization best practice
- flutter.dev Material 3 docs — `ColorScheme.fromSeed`, `NavigationBar`, `useMaterial3: true` default
- Multiple WebSearch results about google_sign_in v7 migration (cross-referenced with official package page)

### Tertiary (LOW confidence)
- Community reports on GitHub issues (#102377, #45847) about ID token refresh limitations — pattern of behavior is consistent across multiple reports but not officially documented as intended behavior
- WebSearch results on GitHub OAuth + Flutter patterns — verified against `oauth2_client` official README

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified on pub.dev with current versions
- Architecture: MEDIUM — patterns derived from official docs but Convex-Flutter OIDC bridge has no official worked example
- Pitfalls: MEDIUM — most pitfalls confirmed by multiple community sources and GitHub issues; token expiry behavior is well-documented as a known limitation
- Convex OIDC bridge specifically: LOW → requires prototype to verify before trusting

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (30 days; `google_sign_in` v7 is actively evolving — check changelog before planning if > 2 weeks pass)
