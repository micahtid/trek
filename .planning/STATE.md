---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: in-progress
stopped_at: Phase 4 context gathered
last_updated: "2026-03-05T03:21:09.763Z"
last_activity: "2026-03-04 -- Completed 03-02: Calendar UI and nudge flow"
progress:
  total_phases: 7
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
---

---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: in-progress
stopped_at: Completed 03-02-PLAN.md
last_updated: "2026-03-04T23:59:00.000Z"
last_activity: "2026-03-04 -- Completed 03-02: Calendar UI and nudge flow (Phase 3 complete)"
progress:
  total_phases: 7
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-27)

**Core value:** Every intern reflection becomes a future resume bullet point — the app actively interviews interns about their work until entries are specific and impactful enough to prove their value.
**Current focus:** Phase 3 complete -- Calendar Integration and Push Notifications (2/2 plans complete). Phase 4 (AI Follow-Up Questioning) next.

## Current Position

Phase: 3 of 7 (Calendar Integration and Push Notifications) -- COMPLETE
Plan: 2 of 2 in current phase (2 complete, 0 remaining)
Status: Phase 3 complete. Ready for Phase 4 (AI Follow-Up Questioning).
Last activity: 2026-03-04 -- Completed 03-02: Calendar UI and nudge flow

Progress: [██████████] 100% (all planned phases through Phase 3 complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 9
- Average duration: 16 min
- Total execution time: 143 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation-and-auth | 4 | 86 min | 22 min |
| 02-daily-canvas | 3 | 15 min | 5 min |
| 03-calendar-integration | 2 | 42 min | 21 min |

**Recent Trend:**
- Last 5 plans: 6 min, 4 min, 5 min, 12 min, ~30 min
- Trend: Multi-session plans with checkpoints take longer; UI+notification wiring is most complex

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-Phase 1]: `google_generative_ai` is deprecated — all AI calls go through `firebase_ai ^3.8.0`
- [Pre-Phase 1]: Convex Auth does not support Flutter — auth requires custom OIDC bridge via `google_sign_in` ID token passed to `convexClient.setAuthWithRefresh()`
- [Pre-Phase 1]: `google_sign_in` supports only one account at a time — secondary Calendar account needs separate OAuth 2.0 flow (deferred to v2 per REQUIREMENTS.md)
- [01-01]: Convex `init` command is deprecated — use `npx convex dev --once --configure=new` for new projects
- [01-01]: `applicationID: "verified"` used as placeholder in auth.config.ts — MUST be replaced with actual Web OAuth 2.0 Client ID from Google Cloud Console before production
- [01-01]: Convex deployment URL is `https://benevolent-antelope-462.convex.cloud` (project: intern-growth-vault, team: micah)
- [01-02]: routerProvider is a Riverpod Provider<GoRouter> — App is a ConsumerWidget watching it; aligns with auth-aware routing Plan 03 will extend
- [01-02]: AppShell is StatelessWidget — tab index derived from URL via GoRouterState.of(context).matchedLocation, no local state
- [01-02]: Auth guard intentionally omitted from router — Plan 03 adds redirect when authNotifierProvider exists
- [01-03]: serverClientId MUST be Web OAuth 2.0 Client ID (not Android/iOS) — without it idToken is null on Android
- [01-03]: Convex deployment renamed from benevolent-antelope-462 (placeholder) to grand-tortoise-682 (actual project)
- [01-03]: Android package renamed from com.example.intern_tracker to com.internvault.app for production identity
- [01-03]: applicationID in convex/auth.config.ts updated to actual Web Client ID — OIDC bridge fully wired
- [01-03]: Convex backend directory is C:/Users/micah/OneDrive/Desktop/intern_vault_backend (separate from Flutter project)
- [01-03]: RouterNotifier pattern chosen for GoRouter refreshListenable — ChangeNotifier subclass watches authNotifierProvider via ref.listen
- [01-04]: GitHub OAuth App configured with Client ID Ov23likLf45h9uWzEz3N and callback URL com.internvault.app://oauth2redirect
- [01-04]: GitHub read:user scope only in Phase 1 — repo scope deferred to Phase 5 (incremental auth pattern)
- [01-04]: Calendar scope stored in local Riverpod state only — actual Calendar API calls happen in Phase 3
- [01-04]: Android intent-filter registered for com.internvault.app://oauth2redirect to handle OAuth callback via flutter_web_auth_2
- [01-04]: Settings-only integrations — Calendar and GitHub connections live in Settings only, never in onboarding
- [02-01]: userId is v.string() not v.id("users") in entries table — matches auth pattern where userId can be Convex doc ID or Google ID fallback
- [02-01]: No explicit timestamp on entries — Convex _creationTime (auto-set Unix ms) is sufficient for time queries
- [02-01]: ConvexClient.subscribe() used for real-time updates — returns SubscriptionHandle with cancel(); preferred over polling
- [02-01]: speech_to_text and intl installed early to avoid pubspec conflicts in Plan 02
- [02-02]: EntryCard uses surfaceContainerLow fill (not elevated shadow) for clean M3 aesthetic
- [02-02]: ComposeSheet inputMethod starts as "text", switches to "voice" on mic use, never reverts
- [02-02]: Delete uses immediate-delete + undo-snackbar re-create pattern (new _id acceptable for few-second window)
- [02-02]: ScaffoldMessenger captured before Navigator.pop for cross-screen snackbar display
- [02-02]: Entry detail uses Navigator.push (not GoRouter) for transient view navigation
- [02-03]: Custom full-screen search page instead of SearchAnchor -- full control over date filtering and grouped results
- [02-03]: Timer-based debounce (300ms) for search queries -- avoids hammering Convex search index on every keystroke
- [02-03]: Search results grouped by date with section headers using intl DateFormat
- [03-01]: flutter_local_notifications v21 uses all-named-parameter API -- adapted initialize/zonedSchedule/cancel calls
- [03-01]: Convex backend not in git repo -- changes deployed to cloud; TypeScript source at C:/Users/micah/OneDrive/Desktop/intern_vault/back_end/
- [03-01]: GoogleSignInClientAuthorization.accessToken is non-nullable String in google_sign_in v7
- [03-02]: UncontrolledProviderScope with explicit ProviderContainer for notification tap handler access to GoRouter outside widget tree
- [03-02]: AgendaSection starts expanded by default -- collapsible via chevron toggle with AnimatedSize
- [03-02]: EventCard uses left border color accent per status (blue=in_progress, orange=ended, green=reflected, grey=skipped/upcoming)
- [03-02]: Core library desugaring enabled in Android build.gradle.kts for flutter_local_notifications java.time API compatibility
- [03-02]: Silent GoogleSignInException caught gracefully to prevent consent dialog popup on Today tab calendar sync

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 1 - RESOLVED]: Convex-Flutter OIDC bridge is underdocumented — Convex backend deployed with auth.config.ts using custom OIDC (Google); bridge prototype complete in Plan 01
- [Phase 1 - RESOLVED]: Web OAuth 2.0 Client ID created and configured in both auth.config.ts and auth_repository.dart
- [Phase 1]: Multi-account Google OAuth is a non-trivial Flutter limitation — but multi-account Calendar support is deferred to v2, so this is not a current blocker
- [Phase 3 - RESOLVED]: FCM push notifications silently fail for force-quit iOS apps — pull-based catch-up (INTG-04) built alongside push in Plan 02 (lifecycle observer invalidates providers on resume)

## Session Continuity

Last session: 2026-03-05T03:21:09.750Z
Stopped at: Phase 4 context gathered
Resume file: .planning/phases/04-ai-follow-up-questioning/04-CONTEXT.md
