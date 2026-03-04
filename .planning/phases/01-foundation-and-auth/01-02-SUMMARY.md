---
phase: 01-foundation-and-auth
plan: 02
subsystem: ui
tags: [flutter, material3, go_router, riverpod, google_fonts, sora, navigation]

# Dependency graph
requires: []
provides:
  - Flutter app shell with three-tab bottom navigation (Today/Vault/Settings)
  - Material 3 theme with Sora font and amber/gold color scheme
  - GoRouter with ShellRoute wrapping three tab routes
  - Feature-based directory structure ready for parallel development
affects: [01-03, 01-04, all future phases building on the navigation shell]

# Tech tracking
tech-stack:
  added:
    - google_fonts 8.0.2 (Sora font via GoogleFonts.soraTextTheme)
    - go_router 17.1.0 (declarative routing with ShellRoute)
    - riverpod 3.2.1 (dependency injection provider)
    - flutter_riverpod 3.2.1 (Flutter integration for Riverpod)
  patterns:
    - ConsumerWidget in App for Riverpod provider watching
    - Provider<GoRouter> for router as a Riverpod provider
    - ShellRoute wrapping tab routes for persistent bottom nav
    - NoTransitionPage for tab switches (no slide animation on tab change)
    - GoRouterState.of(context).matchedLocation for active tab detection

key-files:
  created:
    - lib/app.dart
    - lib/core/theme/app_theme.dart
    - lib/core/router/app_router.dart
    - lib/features/shell/app_shell.dart
    - lib/features/today/today_screen.dart
    - lib/features/vault/vault_screen.dart
    - lib/features/settings/settings_screen.dart
  modified:
    - lib/main.dart (replaced NotesApp with ProviderScope entry point)
    - pubspec.yaml (added 4 new dependencies)

key-decisions:
  - "Sora font applied globally via GoogleFonts.soraTextTheme() on base ThemeData"
  - "Amber seed color 0xFFFFC107 (amber[500]) for ColorScheme.fromSeed — light theme only"
  - "NavigationBar (Material 3) used instead of BottomNavigationBar (M2 legacy)"
  - "routerProvider is a Riverpod Provider<GoRouter> so App can watch it as ConsumerWidget"
  - "NoTransitionPage used for tab switches — no animation on bottom nav tab change"
  - "AppShell is StatelessWidget — GoRouter handles tab state via URL, no local state needed"
  - "Auth guard intentionally omitted — Plan 03's responsibility when auth state exists"

patterns-established:
  - "Feature-based structure: lib/features/{feature}/{feature}_screen.dart"
  - "Core infrastructure: lib/core/{concern}/{file}.dart"
  - "All providers declared in their respective core/ or features/ file, not a central registry"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-04]

# Metrics
duration: 9min
completed: 2026-03-02
---

# Phase 1 Plan 02: App Shell and Navigation Summary

**Flutter app restructured from monolithic NotesApp to feature-based architecture with Material 3 NavigationBar (Today/Vault/Settings), Sora font via google_fonts, amber ColorScheme.fromSeed, and GoRouter ShellRoute**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-02T21:07:18Z
- **Completed:** 2026-03-02T21:16:00Z
- **Tasks:** 2
- **Files modified:** 9 (7 created, 2 modified)

## Accomplishments
- Replaced the placeholder NotesApp with a clean ProviderScope + MaterialApp.router architecture
- Established the Sora font and amber/gold Material 3 design system used by every subsequent feature
- GoRouter ShellRoute delivers persistent bottom navigation with Today/Vault/Settings tabs
- Feature-based directory structure created, ready for Plans 03-04 and beyond

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dependencies and create theme + app entry point** - `5151002` (feat)
2. **Task 2: Create router, navigation shell, and placeholder screens** - `6774d1f` (feat)

## Files Created/Modified
- `lib/main.dart` - Replaced NotesApp with ProviderScope entry point
- `lib/app.dart` - MaterialApp.router with Sora theme and amber color scheme
- `lib/core/theme/app_theme.dart` - buildAppTheme() with ColorScheme.fromSeed(amber)
- `lib/core/router/app_router.dart` - GoRouter with ShellRoute for tab navigation
- `lib/features/shell/app_shell.dart` - NavigationBar scaffold wrapping tab content
- `lib/features/today/today_screen.dart` - Placeholder (Phase 2 target)
- `lib/features/vault/vault_screen.dart` - Placeholder (Phase 6 target)
- `lib/features/settings/settings_screen.dart` - Placeholder (Plan 03/04 target)
- `pubspec.yaml` - Added google_fonts, go_router, riverpod, flutter_riverpod

## Decisions Made
- Used `routerProvider = Provider<GoRouter>` so App is a ConsumerWidget — aligns with the Riverpod pattern that Plan 03 will extend for auth-aware routing
- `AppShell` is `StatelessWidget` rather than `StatefulWidget` — tab index derived from URL location, not local state, preventing desync
- `NoTransitionPage` for tab switches — standard mobile pattern, prevents slide animation between bottom nav tabs
- Auth guard omitted intentionally — Plan 03 adds redirect when `authNotifierProvider` exists

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Flutter binary was not in PATH; found at `/c/src/flutter/bin/flutter` — used full path for all commands
- Windows Developer Mode warning about symlinks appeared during `pub add` — expected on Windows, does not affect APK builds (confirmed: built successfully)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- App shell, navigation, and design system are complete
- Plan 03 (Google OAuth sign-in) can add `/sign-in` route to `app_router.dart` and auth guard to `routerProvider`
- Plan 04 (Convex integration) can extend `main.dart` with ConvexClient initialization before ProviderScope
- All placeholder screens have `AppBar` and `Scaffold` — ready to receive real content

---
*Phase: 01-foundation-and-auth*
*Completed: 2026-03-02*
