---
phase: 01-foundation-and-auth
verified: 2026-03-03T00:00:00Z
status: passed
score: 5/5 must-haves verified
re_verification: false
human_verification:
  - test: "Sign in with Google on a real Android device"
    expected: "Sign-in sheet appears, user lands on Today tab, session persists after app kill/reopen"
    why_human: "Google OAuth requires device hardware (camera/browser), cannot be verified programmatically"
  - test: "Grant Google Calendar permission from Settings"
    expected: "Google prompts only for Calendar permission (not full re-sign-in), then shows Connected"
    why_human: "authorizeScopes() requires live Google session and on-device consent dialog"
  - test: "Connect GitHub from Settings"
    expected: "Browser opens for GitHub OAuth, returns to app, shows GitHub username"
    why_human: "OAuth browser flow requires live devices and configured GitHub OAuth App"
  - test: "Sign out from Settings and verify data inaccessibility"
    expected: "Redirected to sign-in screen, Convex mutations fail (not authenticated), re-sign-in works"
    why_human: "Requires running app and live Convex backend to verify auth gate"
---

# Phase 1: Foundation and Auth Verification Report

**Phase Goal:** Users can sign into the app with Google and have their identity securely connected to Convex
**Verified:** 2026-03-03
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can sign in with Google OAuth and land on the main app screen | VERIFIED | `sign_in_screen.dart` calls `authNotifierProvider.notifier.signIn()`; router redirect guard in `app_router.dart` sends authenticated users to `/today` |
| 2 | User reopens the app after closing it and remains signed in (session persists via Convex token refresh) | VERIFIED | `convex_service.dart` wires `setAuthWithRefresh` with `fetchToken` callback that calls `attemptSilentSignIn()`; `auth_repository.dart` calls `attemptLightweightAuthentication()` on initialize |
| 3 | User can sign out and is redirected to the login screen with all user-scoped data inaccessible | VERIFIED | `settings_screen.dart` sign-out tile calls `authNotifierProvider.notifier.signOut()`; router redirect guard redirects unauthenticated users to `/sign-in` |
| 4 | User can grant Google Calendar read permission as a separate optional step after initial sign-in | VERIFIED | `calendar_auth_section.dart` calls `GoogleSignIn.instance.authorizationClient.authorizeScopes(['https://www.googleapis.com/auth/calendar.readonly'])` |
| 5 | User can optionally connect a GitHub account from settings without disrupting their Google session | VERIFIED | `github_auth_section.dart` uses `GitHubOAuth2Client` independently of `google_sign_in`; token stored in `FlutterSecureStorage`; no Google session interaction |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `convex/auth.config.ts` | OIDC provider config for Google | VERIFIED | Contains `domain: "https://accounts.google.com"` and real Web Client ID `559229937063-sp4cfdk9dn3uano0g84f6ei502j7tvh7.apps.googleusercontent.com` |
| `convex/schema.ts` | Users table definition | VERIFIED | `defineTable` with `googleId`, `email`, `name`, `avatarUrl`, `githubConnected`, `lastSignIn`, indexes `by_googleId` and `by_email` |
| `convex/tsconfig.json` | TypeScript config for Convex | VERIFIED | File exists |
| `package.json` | Convex backend dependencies | VERIFIED | `convex: ^1.32.0` and `typescript: ^5.9.3` |
| `lib/main.dart` | App entry point with ProviderScope | VERIFIED | `initConvexClient()` called before `runApp(ProviderScope(...))`, 24 lines |
| `lib/app.dart` | MaterialApp.router with theme and router | VERIFIED | `MaterialApp.router` with `buildAppTheme()` and `routerProvider` |
| `lib/core/theme/app_theme.dart` | ThemeData with Sora font and amber ColorScheme | VERIFIED | `GoogleFonts.soraTextTheme(base.textTheme)`, `ColorScheme.fromSeed(seedColor: Color(0xFFFFC107))`, `useMaterial3: true` |
| `lib/core/router/app_router.dart` | GoRouter with ShellRoute, auth guard, refreshListenable | VERIFIED | `ShellRoute`, `redirect` guard, `_RiverpodRefreshListenable` ChangeNotifier, `/sign-in` route outside ShellRoute |
| `lib/features/shell/app_shell.dart` | Scaffold with NavigationBar | VERIFIED | `NavigationBar` with Today/Vault/Settings `NavigationDestination` items |
| `lib/features/today/today_screen.dart` | Placeholder Today screen | VERIFIED | Intentional Phase 1 placeholder — "Daily Canvas — coming in Phase 2" |
| `lib/features/vault/vault_screen.dart` | Placeholder Vault screen | VERIFIED | Intentional Phase 1 placeholder — "Vault — coming in Phase 6" |
| `lib/features/settings/settings_screen.dart` | Full settings with profile, sign-out, integrations | VERIFIED | Profile section (avatar/name/email from `AuthStateAuthenticated`), `CalendarAuthSection`, `GitHubAuthSection`, sign-out tile calling `signOut()` |
| `lib/features/auth/domain/auth_state.dart` | Sealed AuthState class | VERIFIED | `sealed class AuthState` with `AuthStateUnauthenticated`, `AuthStateLoading`, `AuthStateAuthenticated` |
| `lib/features/auth/data/auth_repository.dart` | google_sign_in v7 event stream wrapper | VERIFIED | `authenticate()`, `attemptLightweightAuthentication()`, `authenticationEvents` stream subscription, `kGoogleWebClientId` set to real Web Client ID |
| `lib/features/auth/presentation/auth_provider.dart` | Riverpod AsyncNotifier auth lifecycle | VERIFIED | `AsyncNotifier<AuthState>`, `signIn()`, `signOut()`, `_setupConvexAuth()`, Convex `upsertUser` mutation call |
| `lib/features/auth/presentation/sign_in_screen.dart` | Sign-in UI with logo, tagline, Google button | VERIFIED | Logo area, "Every day builds your future." tagline, "Sign in with Google" OutlinedButton, CircularProgressIndicator loading state, SnackBar error display; 234 lines |
| `lib/core/convex/convex_service.dart` | ConvexClient init with setAuthWithRefresh | VERIFIED | `setAuthWithRefresh` with `fetchToken` callback, `clearAuth()` on sign-out, `kConvexDeploymentUrl = 'https://grand-tortoise-682.convex.cloud'` |
| `convex/users.ts` | Convex upsertUser mutation | VERIFIED | `mutation` with `ctx.auth.getUserIdentity()` guard, `by_googleId` index lookup, insert or patch |
| `lib/features/settings/calendar_auth_section.dart` | Calendar scope grant UI | VERIFIED | `authorizeScopes(['https://www.googleapis.com/auth/calendar.readonly'])` called on button tap |
| `lib/features/settings/github_auth_section.dart` | GitHub OAuth UI and logic | VERIFIED | `GitHubOAuth2Client`, `getTokenWithAuthCodeFlow`, `FlutterSecureStorage` write, GitHub `/user` API call for username |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/main.dart` | `lib/app.dart` | `runApp(ProviderScope(child: App()))` | WIRED | `ProviderScope` present, `App()` imported and used |
| `lib/app.dart` | `lib/core/router/app_router.dart` | `MaterialApp.router` uses `routerProvider` | WIRED | `ref.watch(routerProvider)` with `routerConfig: router` |
| `lib/core/router/app_router.dart` | `lib/features/shell/app_shell.dart` | `ShellRoute` wraps tab screens in `AppShell` | WIRED | `ShellRoute(builder: (context, state, child) => AppShell(child: child), ...)` |
| `lib/features/auth/presentation/sign_in_screen.dart` | `lib/features/auth/presentation/auth_provider.dart` | Button tap calls `authNotifier.signIn()` | WIRED | `ref.read(authNotifierProvider.notifier).signIn()` in `onPressed` |
| `lib/features/auth/presentation/auth_provider.dart` | `lib/features/auth/data/auth_repository.dart` | Notifier delegates to repository | WIRED | `ref.read(authRepositoryProvider)` used in `build()`, `signIn()`, `signOut()` |
| `lib/features/auth/data/auth_repository.dart` | `lib/core/convex/convex_service.dart` | ID token flows to Convex `fetchToken` callback | WIRED | `repo.attemptSilentSignIn()` called in `ConvexService.instance.setupAuth(fetchToken: ...)` |
| `lib/core/convex/convex_service.dart` | `convex/auth.config.ts` | `setAuthWithRefresh` sends token validated by OIDC | WIRED | `setAuthWithRefresh` called with `fetchToken`; `kConvexDeploymentUrl` points to deployed backend with matching `applicationID` |
| `lib/features/auth/presentation/auth_provider.dart` | `lib/core/router/app_router.dart` | Auth state change triggers router redirect | WIRED | `_RiverpodRefreshListenable` listens to `authNotifierProvider` via `ref.listen`, calls `notifyListeners()` on every state change; router's `refreshListenable` bound to this |
| `lib/features/settings/settings_screen.dart` | `lib/features/auth/presentation/auth_provider.dart` | Sign-out button calls `authNotifier.signOut()` | WIRED | `ref.read(authNotifierProvider.notifier).signOut()` in `onTap` handler |
| `lib/features/settings/calendar_auth_section.dart` | `google_sign_in authorizeScopes` | Calendar scope grant via `authorizeScopes()` | WIRED | `GoogleSignIn.instance.authorizationClient.authorizeScopes([_calendarReadonlyScope])` |
| `lib/features/settings/github_auth_section.dart` | `oauth2_client GitHubOAuth2Client` | GitHub OAuth browser flow | WIRED | `GitHubOAuth2Client(redirectUri: _kRedirectUri, customUriScheme: _kRedirectScheme)` with `getTokenWithAuthCodeFlow` |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| AUTH-01 | 01-01, 01-02, 01-03 | User can sign up and sign in with Google OAuth | SATISFIED | `sign_in_screen.dart` → `auth_provider.dart` → `auth_repository.dart` → google_sign_in v7; `users:upsertUser` creates record on first sign-in |
| AUTH-02 | 01-01, 01-02, 01-03 | User session persists across app restarts | SATISFIED | `convex_service.dart` `setAuthWithRefresh` + `fetchToken` callback using `attemptLightweightAuthentication()`; Convex refreshes token 60s before expiry |
| AUTH-03 | 01-02, 01-04 | User can optionally grant Google Calendar read permission | SATISFIED | `calendar_auth_section.dart` calls `authorizeScopes(['https://www.googleapis.com/auth/calendar.readonly'])`; incremental scope, no re-sign-in |
| AUTH-04 | 01-02, 01-04 | User can optionally connect a GitHub account | SATISFIED | `github_auth_section.dart` uses `GitHubOAuth2Client` with `read:user` scope; token stored in `FlutterSecureStorage`; persists across restarts |

All 4 requirements for Phase 1 are satisfied. No orphaned requirements found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `convex/auth.config.ts` | 27 | `TODO: Replace with actual Web Client ID` comment | Info | Comment is stale — the actual Web Client ID IS already set to `559229937063-sp4cfdk9dn3uano0g84f6ei502j7tvh7.apps.googleusercontent.com`. The TODO is misleading but functionally harmless. |
| `lib/features/auth/data/auth_repository.dart` | 12 | `SETUP REQUIRED: Replace this placeholder` comment | Info | Same stale comment — the `kGoogleWebClientId` constant IS set to the real value. Comment is misleading but harmless. |
| `lib/features/settings/github_auth_section.dart` | 32 | `kGitHubClientSecret` embedded in source | Warning | GitHub OAuth client secret (`f1cacf9d...`) is in source code. Acknowledged in plan as acceptable for Phase 1 with a note to revisit in Phase 5. Not a Phase 1 blocker, but must be addressed before any public repo publication. |
| `lib/features/today/today_screen.dart` | 10 | `'Daily Canvas — coming in Phase 2'` | Info | Intentional Phase 1 placeholder — this is the expected and correct state per the plan. |
| `lib/features/vault/vault_screen.dart` | 10 | `'Vault — coming in Phase 6'` | Info | Intentional Phase 1 placeholder — correct per plan. |

**Severity summary:** 0 Blockers, 1 Warning (GitHub secret in source), 4 Info items

### Dual Convex Backend Observation

During verification, two Convex deployments were found:

1. **`benevolent-antelope-462`** (old): Located at `C:/Users/micah/OneDrive/Desktop/intern_tracker/convex/` with `.env.local` pointing to this deployment. Created in Plan 01-01 as the initial project.

2. **`grand-tortoise-682`** (live): Located at `C:/Users/micah/OneDrive/Desktop/intern_vault_backend/convex/` with `.env.local` pointing to this deployment. Created in Plan 01-03 as the renamed/reconfigured backend.

The Flutter app at `convex_service.dart` correctly uses `grand-tortoise-682` (the live backend). The `convex/` directory inside the Flutter project is a stale artifact from Plan 01-01 and is not used by the running app. Both backends have identical `auth.config.ts`, `schema.ts`, and `users.ts` source files with the real Web Client ID set. This is not a blocker — the running app connects to the correct backend.

The stale `convex/` directory in the Flutter project could cause confusion in future phases. It is flagged as an informational item for cleanup.

### Human Verification Required

#### 1. Google Sign-In End-to-End Flow

**Test:** Run `flutter run` on an Android device or emulator. Verify the sign-in screen appears. Tap "Sign in with Google." Complete the Google sign-in flow.
**Expected:** User lands on the Today tab with bottom navigation visible. Sora font and amber theme are visible throughout.
**Why human:** Google OAuth requires live device hardware and a real Google account. The OIDC bridge (Convex `setAuthWithRefresh` + `fetchToken`) cannot be verified without a running app and live Convex backend.

#### 2. Session Persistence After App Kill

**Test:** After signing in, fully kill the app (remove from recents). Reopen it.
**Expected:** User is already signed in — goes directly to Today tab without seeing the sign-in screen.
**Why human:** `attemptLightweightAuthentication()` behavior depends on the device's cached credential store and Convex's silent token refresh. Cannot be verified statically.

#### 3. Sign Out Flow

**Test:** Navigate to Settings. Tap "Sign Out." Confirm in the dialog.
**Expected:** Redirected to sign-in screen. All user-scoped Convex data is inaccessible (unauthenticated mutations throw). Re-sign-in works correctly.
**Why human:** Router redirect behavior after `signOut()` requires a running app. Convex mutation auth enforcement requires a live backend call.

#### 4. Google Calendar Incremental Scope Grant

**Test:** Sign in. Navigate to Settings > Connections > Google Calendar. Tap "Connect."
**Expected:** Google presents a Calendar-only permission dialog (no full re-sign-in). After granting, the section shows "Connected — read access granted." Reopening Settings does NOT persist the Connected state (this is by design — Calendar state is local Riverpod state, resets on restart until Phase 3 adds persistence).
**Why human:** `authorizeScopes()` requires a live Google session and on-device consent dialog.

#### 5. GitHub OAuth Connection

**Test:** Sign in. Navigate to Settings > Connections > GitHub. Tap "Connect." Complete GitHub authorization in the browser.
**Expected:** Returns to the app. GitHub section shows "Connected" with the GitHub username. Killing and reopening the app still shows Connected (token persisted in `FlutterSecureStorage`). Google session is not disrupted.
**Why human:** OAuth browser redirect flow requires real devices, a configured GitHub OAuth App, and the `com.internvault.app://oauth2redirect` URI scheme registered in Android.

### Gaps Summary

No gaps found. All five observable truths from the Phase 1 Success Criteria are verified at all three levels (exists, substantive, wired). All four requirements (AUTH-01 through AUTH-04) are satisfied with implementation evidence.

The phase delivered:
- Convex backend deployed with Google OIDC custom auth at `grand-tortoise-682`
- Flutter app shell with Material 3 NavigationBar, Sora font, and amber theme
- Complete Google sign-in flow with Riverpod auth state and GoRouter auth guard
- Session persistence via Convex `setAuthWithRefresh` + google_sign_in `attemptLightweightAuthentication`
- Settings screen with profile display, sign-out, Calendar scope grant, and GitHub OAuth connection
- GitHub token persisted in `FlutterSecureStorage`

Human verification items remain as per above — these require a running device and cannot be verified statically.

---
_Verified: 2026-03-03_
_Verifier: Claude (gsd-verifier)_
