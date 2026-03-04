---
phase: 01-foundation-and-auth
plan: "04"
subsystem: auth
tags: [flutter, google-sign-in, oauth2, github-oauth, calendar, flutter_secure_storage, oauth2_client]

# Dependency graph
requires:
  - phase: 01-03
    provides: authNotifierProvider, AuthStateAuthenticated (displayName, email, avatarUrl), signOut(), GoRouter auth guard

provides:
  - Settings screen with profile display (name, email, avatar from Google auth state)
  - Sign-out flow from Settings redirecting to sign-in screen
  - Incremental Google Calendar scope grant (calendar.readonly) via authorizeScopes() — no re-sign-in
  - GitHub OAuth Authorization Code flow via GitHubOAuth2Client (read:user scope only)
  - GitHub access token persisted in FlutterSecureStorage
  - GitHub username fetched and displayed after connection via /user API
  - Android intent-filter for com.internvault.app://oauth2redirect OAuth callback

affects:
  - Phase 3 (calendar integration will use the granted scope)
  - Phase 5 (GitHub integration will add repo scope incrementally on top of read:user token)

# Tech tracking
tech-stack:
  added:
    - flutter_secure_storage ^10.0.0 (secure GitHub token storage — Keychain/Keystore)
    - oauth2_client ^4.2.3 (GitHubOAuth2Client for Authorization Code flow)
    - http ^1.6.0 (GitHub /user API call to fetch username after connect)
  patterns:
    - Incremental scope grant pattern — Calendar scope added via authorizeScopes() without disrupting Google session
    - Independent OAuth pattern — GitHub OAuth runs completely independently of google_sign_in; no session conflict
    - Secure token storage pattern — OAuth tokens in FlutterSecureStorage, never SharedPreferences
    - Settings-only integration pattern — all optional connections (Calendar, GitHub) live in Settings only, never in onboarding

key-files:
  created:
    - lib/features/settings/calendar_auth_section.dart
    - lib/features/settings/github_auth_section.dart
  modified:
    - lib/features/settings/settings_screen.dart
    - pubspec.yaml
    - android/app/src/main/AndroidManifest.xml

key-decisions:
  - "GitHub OAuth App configured with callback URL com.internvault.app://oauth2redirect and kGitHubClientId set to actual value Ov23likLf45h9uWzEz3N"
  - "GitHub read:user scope only in Phase 1 — repo scope deferred to Phase 5 when actually needed (incremental auth pattern)"
  - "Calendar scope stored in local Riverpod state — actual Calendar API calls happen in Phase 3, not here"
  - "Android intent-filter registered for com.internvault.app://oauth2redirect to handle OAuth callback via flutter_web_auth_2"
  - "GitHub OAuth uses GitHubOAuth2Client from oauth2_client — completely independent of google_sign_in, no session disruption risk"

patterns-established:
  - "Settings-only integrations: optional third-party connections (Calendar, GitHub) live in Settings only — never prompted during onboarding or sign-in"
  - "Incremental scopes: use authorizeScopes() to add Google scopes post-sign-in; never include them in the initial signIn() call"
  - "Independent OAuth: non-Google OAuth flows (GitHub) use oauth2_client and do not touch the google_sign_in session"
  - "Secure token storage: OAuth access tokens go in FlutterSecureStorage; local connection state in Riverpod"

requirements-completed: [AUTH-03, AUTH-04]

# Metrics
duration: 25min
completed: 2026-03-03
---

# Phase 1 Plan 04: Settings Screen with Calendar and GitHub Auth Summary

**Settings screen with profile display, sign-out, incremental Google Calendar scope grant (authorizeScopes), and GitHub OAuth Authorization Code flow (read:user) stored in FlutterSecureStorage**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-02T17:00:00Z
- **Completed:** 2026-03-03T06:12:16Z
- **Tasks:** 2 (1 auto, 1 human-verify checkpoint)
- **Files modified:** 11

## Accomplishments

- Full Settings screen with profile (Google avatar, display name, email from auth state), Connections section, and destructive sign-out tile
- Google Calendar incremental scope grant via `GoogleSignIn.instance.authorizationClient.authorizeScopes()` — no re-sign-in, calendar.readonly scope only, consistent with Phase 1 research pitfall 5
- GitHub OAuth Authorization Code flow via `GitHubOAuth2Client`; token stored in `FlutterSecureStorage`; GitHub username fetched from `/user` API and displayed after connection
- GitHub OAuth App created and configured with actual Client ID (`Ov23likLf45h9uWzEz3N`) and callback URL `com.internvault.app://oauth2redirect`
- Android intent-filter registered for OAuth callback; `dart analyze` passes with zero issues

## Task Commits

Each task was committed atomically:

1. **Task 1: Build Settings screen with profile, sign-out, and integration sections** - `96fab02` (feat)
2. **Task 2: Human-verify checkpoint** - APPROVED by user (no commit)

## Files Created/Modified

- `lib/features/settings/settings_screen.dart` - Full settings screen: profile section (avatar/name/email), Connections section with CalendarAuthSection and GitHubAuthSection, sign-out tile calling authNotifier.signOut()
- `lib/features/settings/calendar_auth_section.dart` - Calendar scope grant UI; calls authorizeScopes(['https://www.googleapis.com/auth/calendar.readonly']); shows connected/not-connected state
- `lib/features/settings/github_auth_section.dart` - GitHub OAuth flow via GitHubOAuth2Client; stores token in FlutterSecureStorage; fetches and displays GitHub username after connect
- `pubspec.yaml` - Added flutter_secure_storage ^10.0.0, oauth2_client ^4.2.3, http ^1.6.0
- `android/app/src/main/AndroidManifest.xml` - Added intent-filter for com.internvault.app://oauth2redirect OAuth callback

## Decisions Made

- **GitHub Client ID set to actual value:** The orchestrator updated `kGitHubClientId` to `Ov23likLf45h9uWzEz3N` and `kGitHubClientSecret` to the actual secret after the GitHub OAuth App was created. These are embedded in `github_auth_section.dart` as constants.
- **Callback URL is `com.internvault.app://oauth2redirect`:** The plan originally used `com.interngrowthvault://oauth2redirect` but the actual Android package (set in plan 01-03) is `com.internvault.app`. The correct URI scheme was used consistently.
- **read:user scope only:** GitHub connection grants only `read:user` in Phase 1. The `repo` scope for commits/PRs is deferred to Phase 5 per the incremental authorization strategy from Phase 1 research.
- **Calendar scope in local state only:** The granted-state for Calendar is held in Riverpod local state. No Convex write needed here — actual Calendar API calls happen in Phase 3.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Callback URI scheme corrected from com.interngrowthvault to com.internvault.app**
- **Found during:** Task 1 (Settings screen implementation)
- **Issue:** Plan specified `com.interngrowthvault://oauth2redirect` but the Android package ID set in Plan 01-03 is `com.internvault.app`. Using the wrong scheme would cause the OAuth callback to never return to the app.
- **Fix:** Used `com.internvault.app://oauth2redirect` in both AndroidManifest.xml intent-filter and GitHubOAuth2Client constructor
- **Files modified:** android/app/src/main/AndroidManifest.xml, lib/features/settings/github_auth_section.dart
- **Verification:** Consistent URI scheme between GitHub OAuth App configuration and app intent-filter; dart analyze passes
- **Committed in:** 96fab02 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — callback URI mismatch)
**Impact on plan:** Essential correction. Using the wrong URI scheme would silently break the GitHub OAuth flow at runtime. No scope creep.

## Issues Encountered

None beyond the URI scheme correction above. `dart analyze` passed with zero issues on the first run. GitHub OAuth and Calendar scope flows verified working by user.

## User Setup Required

The GitHub OAuth App is already configured:

- **GitHub OAuth App:** Created at https://github.com/settings/developers
- **Client ID:** `Ov23likLf45h9uWzEz3N` (set in `github_auth_section.dart`)
- **Callback URL:** `com.internvault.app://oauth2redirect` (registered in GitHub App settings and AndroidManifest.xml)

For Phase 3 (Calendar integration):

- **Google Cloud Console:** Ensure the Calendar API (`calendar.readonly`) is enabled in the Google Cloud project used for the OAuth credentials.

## Next Phase Readiness

Phase 1 auth surface area is complete:

- AUTH-01 (Google sign-in): complete in Plan 01-03
- AUTH-02 (Riverpod auth state + GoRouter guard): complete in Plan 01-03
- AUTH-03 (Calendar scope grant): complete in this plan
- AUTH-04 (GitHub OAuth connection): complete in this plan

Phase 2 (Data models and Convex schema) can proceed immediately — no auth blockers.

Phase 3 (Calendar integration) has the Calendar scope already granted in Settings; it will use the existing token from `google_sign_in` with the `calendar.readonly` scope.

Phase 5 (GitHub integration) has the `read:user` connection; it will add `repo` scope incrementally using the same `oauth2_client` pattern established here.

---
*Phase: 01-foundation-and-auth*
*Completed: 2026-03-03*
