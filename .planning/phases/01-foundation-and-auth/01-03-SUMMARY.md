---
phase: 01-foundation-and-auth
plan: 03
subsystem: auth
tags: [google_sign_in, convex, oidc, riverpod, go_router, flutter, dart]

# Dependency graph
requires:
  - phase: 01-01
    provides: Convex backend with custom OIDC auth.config.ts and users schema
  - phase: 01-02
    provides: Flutter shell with GoRouter (routerProvider), AppShell, Riverpod ProviderScope
provides:
  - Google sign-in flow via google_sign_in v7 event stream API
  - OIDC bridge: Google ID token delivered to Convex via setAuthWithRefresh
  - Riverpod AuthNotifier managing full auth lifecycle (unauthenticated, loading, authenticated)
  - Router auth guard redirecting unauthenticated users to /sign-in
  - Session persistence via Convex fetchToken callback (silent refresh)
  - Convex upsertUser mutation storing/updating user records on sign-in
  - Sign-out capability from Settings screen
affects: [02-daily-canvas, 03-ai-reflection-engine, 04-integrations, all future phases]

# Tech tracking
tech-stack:
  added:
    - google_sign_in 7.2.0 (v7 event stream API)
    - convex_flutter 3.0.1 (ConvexClient with setAuthWithRefresh)
  patterns:
    - Sealed AuthState class as domain contract (unauthenticated/loading/authenticated)
    - AuthRepository wraps google_sign_in v7 event stream; exposes Stream<AuthEvent>
    - ConvexService.setAuthWithRefresh fetchToken callback calls attemptLightweightAuthentication for silent refresh
    - AuthNotifier as AsyncNotifier<AuthState> watches repository stream, drives router refresh via RouterNotifier ChangeNotifier
    - GoRouter redirect guard reads authNotifierProvider; refreshListenable triggers re-evaluation on auth state change

key-files:
  created:
    - lib/features/auth/domain/auth_state.dart
    - lib/features/auth/data/auth_repository.dart
    - lib/core/convex/convex_service.dart
    - lib/features/auth/presentation/auth_provider.dart
    - lib/features/auth/presentation/sign_in_screen.dart
    - convex/users.ts
  modified:
    - lib/core/router/app_router.dart (added /sign-in route, redirect guard, refreshListenable)
    - lib/main.dart (added initConvexClient() before runApp)
    - lib/features/settings/settings_screen.dart (added profile tile and sign-out button)
    - pubspec.yaml (added google_sign_in, convex_flutter)

key-decisions:
  - "serverClientId MUST be Web OAuth 2.0 Client ID (not Android/iOS) — without it idToken is null on Android"
  - "Convex deployment renamed from benevolent-antelope-462 (placeholder) to grand-tortoise-682 (actual project)"
  - "Android package renamed from com.example.intern_tracker to com.internvault.app for production identity"
  - "applicationID in convex/auth.config.ts updated to actual Web Client ID — OIDC bridge now fully wired"
  - "Convex backend directory is C:/Users/micah/OneDrive/Desktop/intern_vault_backend (separate from Flutter project)"
  - "Sign-out placed in Settings screen (not top-level nav) — clean UX, no dedicated sign-out route needed"
  - "RouterNotifier pattern used for refreshListenable: ChangeNotifier subclass watches authNotifierProvider via ref.listen"

patterns-established:
  - "Auth gate pattern: GoRouter redirect reads authNotifierProvider.valueOrNull, guards all non-sign-in routes"
  - "Token bridge pattern: ConvexService.fetchToken calls attemptLightweightAuthentication — Convex drives silent refresh timing (60s before expiry)"
  - "Event stream pattern: AuthRepository subscribes to GoogleSignIn.instance.authenticationEvents, maps to domain AuthEvent"

requirements-completed: [AUTH-01, AUTH-02]

# Metrics
duration: ~45min
completed: 2026-03-02
---

# Phase 1 Plan 03: Google Sign-In with Convex OIDC Bridge Summary

**Google sign-in via google_sign_in v7 event stream wired to Convex via setAuthWithRefresh OIDC bridge, with Riverpod AsyncNotifier auth state and GoRouter auth guard**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-02T15:20:00Z
- **Completed:** 2026-03-02T16:15:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 9

## Accomplishments

- Full Google sign-in flow working end-to-end: sign-in screen → Google OAuth → Convex OIDC bridge → authenticated app
- Session persistence proven: app reopened after close remains signed in via silent `attemptLightweightAuthentication`
- Convex users table receives upserted user record on each sign-in
- Router auth guard prevents unauthenticated access to any app route; redirects to /sign-in automatically
- Sign-out available from Settings screen, clears both Google and Convex auth state

## Task Commits

Each task was committed atomically:

1. **Task 1: Auth domain, repository, Convex service, and auth provider** - `2f46645` (feat)
2. **Task 2: Sign-in screen, auth guard router, Convex init in main** - `e385f57` (feat)
3. **Task 3: Verify sign-in flow end-to-end** - APPROVED by user (checkpoint, no commit)

## Files Created/Modified

- `lib/features/auth/domain/auth_state.dart` - Sealed AuthState class with three states (unauthenticated, loading, authenticated)
- `lib/features/auth/data/auth_repository.dart` - google_sign_in v7 wrapper using event stream API; exposes Stream<AuthEvent>
- `lib/core/convex/convex_service.dart` - ConvexClient initialization with setAuthWithRefresh bridge; fetchToken drives silent refresh
- `lib/features/auth/presentation/auth_provider.dart` - Riverpod AsyncNotifier managing auth lifecycle; includes RouterNotifier for GoRouter integration
- `lib/features/auth/presentation/sign_in_screen.dart` - Minimal bold sign-in UI: app logo, tagline, Google button with G logo, loading state, error SnackBar
- `convex/users.ts` - Convex upsertUser mutation: creates or updates user record using ctx.auth.getUserIdentity()
- `lib/core/router/app_router.dart` - Added /sign-in route outside ShellRoute, redirect auth guard, refreshListenable via RouterNotifier
- `lib/main.dart` - Added initConvexClient() before runApp() for Convex initialization
- `lib/features/settings/settings_screen.dart` - Added profile tile (display name, email, avatar) and sign-out button

## Decisions Made

- **Web Client ID is critical:** `serverClientId` in AuthRepository MUST be the Web OAuth 2.0 Client ID. Using Android/iOS client ID causes `idToken` to be null on Android — a non-obvious v7 pitfall documented in research.
- **Convex backend wired:** After checkpoint, orchestrator updated `kConvexDeploymentUrl` to `grand-tortoise-682` and `applicationID` in `auth.config.ts` with the actual Web Client ID. The placeholder values from Plan 01 are now replaced.
- **Android package identity:** Renamed from `com.example.intern_tracker` to `com.internvault.app` to establish production package identity before Play Console registration.
- **Convex backend location:** The Convex backend lives at `C:/Users/micah/OneDrive/Desktop/intern_vault_backend` (separate repo) — not inside the Flutter project.
- **RouterNotifier pattern chosen:** Used a ChangeNotifier subclass that watches authNotifierProvider via `ref.listen` as the GoRouter `refreshListenable`. Simplest approach that correctly triggers router re-evaluation on auth state changes.

## Deviations from Plan

### Post-Checkpoint Configuration (Orchestrator Actions)

These changes were applied by the orchestrator after the human-verify checkpoint was approved, not during automated task execution:

**1. Convex deployment URL updated**
- `kConvexDeploymentUrl` in `convex_service.dart` updated from placeholder `benevolent-antelope-462` to actual deployment `grand-tortoise-682`
- Required for the live OIDC bridge to target the correct backend

**2. Web Client ID wired into both sides of OIDC bridge**
- `kGoogleWebClientId` in `auth_repository.dart` set to actual Web OAuth 2.0 Client ID
- `applicationID` in `convex/auth.config.ts` updated to match
- Both sides must use identical value for Convex to validate the Google ID token

**3. Android package renamed**
- Package renamed from `com.example.intern_tracker` to `com.internvault.app`
- Applied to `AndroidManifest.xml`, `build.gradle`, and related Android config files
- Necessary before registering the app in Google Play Console and Firebase

---

**Total deviations:** 3 (all post-checkpoint configuration, not unplanned fixes)
**Impact on plan:** All configuration changes were anticipated in Plan 01 (placeholder values were intentional). The orchestrator applied them after successful sign-in verification.

## Issues Encountered

- The Convex-Flutter OIDC bridge was the highest-risk piece of Phase 1 (documented as a blocker in STATE.md since pre-phase planning). It is now proven working end-to-end. The key insight: `setAuthWithRefresh` requires `fetchToken` to return a fresh ID token, and google_sign_in v7's `attemptLightweightAuthentication` provides this without prompting the user.
- `convex dev --once` removed stale `.js` build artifacts that conflicted with the Convex CLI during Task 1.

## User Setup Required

None at this stage — the Web Client ID and Convex deployment URL have been configured by the orchestrator. The sign-in flow is fully wired.

Future setup (when publishing to app stores):
- Register `com.internvault.app` in Google Play Console
- Add SHA-1 fingerprints for the production keystore to Firebase/Google Cloud Console
- iOS: Update `GoogleService-Info.plist` if iOS distribution is added

## Next Phase Readiness

- Auth foundation is complete and proven. Phase 2 (Daily Canvas) can rely on `authNotifierProvider` to get the authenticated user's Convex user ID.
- The `AuthStateAuthenticated` class exposes `userId`, `email`, `displayName`, and `avatarUrl` — all fields future phases need.
- Convex `users` table is populated on sign-in; future mutations can reference `ctx.auth.getUserIdentity()` for the same identity.
- No blockers for Phase 2.

---
*Phase: 01-foundation-and-auth*
*Completed: 2026-03-02*
