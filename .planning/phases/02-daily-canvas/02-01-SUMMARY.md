---
phase: 02-daily-canvas
plan: 01
subsystem: database, data-layer
tags: [convex, entries, full-text-search, riverpod, stream-provider, subscription]

# Dependency graph
requires:
  - phase: 01-foundation-and-auth
    provides: ConvexService singleton with mutation/query wrappers, auth state with userId
provides:
  - Convex entries table with userId, body, inputMethod fields and searchIndex on body
  - CRUD mutations (createEntry, updateEntry, deleteEntry) and queries (getEntriesToday, getEntry, searchEntries)
  - Flutter Entry domain model with fromJson factory for Convex document JSON
  - EntryRepository bridging Convex CRUD operations to Dart async methods
  - Riverpod todayEntriesProvider delivering real-time entries via Convex subscription
  - ConvexService.subscribe() wrapper for real-time Convex query subscriptions
affects: [02-02-PLAN (canvas UI), 02-03-PLAN (voice input, search)]

# Tech tracking
tech-stack:
  added: [speech_to_text 7.3.0, intl 0.20.2]
  patterns: [ConvexService.subscribe() for real-time data, StreamProvider.autoDispose for reactive UI state, Entry.fromJson for Convex JSON deserialization]

key-files:
  created:
    - convex/entries.ts
    - lib/features/today/domain/entry.dart
    - lib/features/today/data/entry_repository.dart
    - lib/features/today/presentation/entry_providers.dart
  modified:
    - convex/schema.ts
    - lib/core/convex/convex_service.dart
    - pubspec.yaml

key-decisions:
  - "userId is v.string() not v.id('users') -- matches existing auth pattern where userId can be Convex doc ID or Google ID fallback"
  - "No explicit timestamp field on entries -- _creationTime auto-set by Convex (Unix ms) is sufficient"
  - "ConvexClient.subscribe() returns SubscriptionHandle with cancel() -- real-time subscription preferred over polling"
  - "Removed duplicate .js files alongside .ts in convex/ directory to fix Convex build conflict"

patterns-established:
  - "ConvexService.subscribe() wrapper: consistent pattern for Convex real-time subscriptions throughout the app"
  - "Entry.fromJson: Convex document JSON deserialization with _id and _creationTime mapping"
  - "StreamProvider.autoDispose bridging Convex subscription callbacks into Dart streams"
  - "currentUserIdProvider: centralized userId extraction from auth state for downstream providers"

requirements-completed: [CANV-02, CANV-07]

# Metrics
duration: 6min
completed: 2026-03-03
---

# Phase 02 Plan 01: Entries Data Layer Summary

**Convex entries table with full-text search index, Flutter Entry model with fromJson, EntryRepository CRUD bridge, and real-time todayEntriesProvider via Convex subscription**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-03T21:37:48Z
- **Completed:** 2026-03-03T21:44:00Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Deployed Convex entries table with by_user_creation index and search_body full-text search index
- Created 6 Convex functions: createEntry, updateEntry, deleteEntry (mutations) and getEntriesToday, getEntry, searchEntries (queries)
- Built Flutter data pipeline: Entry model, EntryRepository, and todayEntriesProvider with real-time Convex subscription
- Added ConvexService.subscribe() wrapper exposing convex_flutter SubscriptionHandle API

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Convex entries schema, CRUD mutations, and search query** - `279d996` (feat)
2. **Task 2: Create Flutter Entry model, EntryRepository, and Riverpod providers** - `1e787bd` (feat)

## Files Created/Modified
- `convex/schema.ts` - Added entries table definition with searchIndex on body field
- `convex/entries.ts` - CRUD mutations and queries for Daily Canvas entries
- `lib/features/today/domain/entry.dart` - Entry data model with fromJson factory
- `lib/features/today/data/entry_repository.dart` - Convex CRUD bridge with entryRepositoryProvider
- `lib/features/today/presentation/entry_providers.dart` - currentUserIdProvider and todayEntriesProvider (StreamProvider.autoDispose)
- `lib/core/convex/convex_service.dart` - Added subscribe() wrapper method
- `pubspec.yaml` - Added speech_to_text and intl dependencies

## Decisions Made
- Used `v.string()` for userId (not `v.id("users")`) to match existing auth pattern where userId can be either Convex doc ID or Google ID fallback
- No explicit timestamp field on entries -- Convex `_creationTime` (auto-set Unix ms) is sufficient for time-based queries
- Used `ConvexClient.subscribe()` for real-time updates instead of polling -- returns `SubscriptionHandle` with `cancel()` method
- Installed `speech_to_text` and `intl` in this plan to avoid pubspec conflicts in Plan 02

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed duplicate .js files causing Convex build failure**
- **Found during:** Task 1 (Convex deployment)
- **Issue:** `convex/` directory contained both `.ts` and `.js` files for the same modules (users.js/users.ts, schema.js/schema.ts, auth.config.js/auth.config.ts). Convex esbuild treated both as separate modules and failed with "Two output files share the same path but have different contents"
- **Fix:** Removed the duplicate .js files (users.js, schema.js, auth.config.js) from both the backend and Flutter project directories. The .ts files are the source of truth.
- **Files modified:** convex/users.js (deleted), convex/schema.js (deleted), convex/auth.config.js (deleted)
- **Verification:** `npx convex dev --once --typecheck=enable` succeeded after removal
- **Committed in:** 279d996 (Task 1 commit -- .js files were not git-tracked so no deletion in commit)

**2. [Rule 1 - Bug] Added missing SubscriptionHandle import in entry_providers.dart**
- **Found during:** Task 2 (dart analyze)
- **Issue:** `SubscriptionHandle` type used for the subscription variable was not imported
- **Fix:** Added `import 'package:convex_flutter/convex_flutter.dart' show SubscriptionHandle;`
- **Files modified:** lib/features/today/presentation/entry_providers.dart
- **Verification:** `dart analyze` passes with zero errors
- **Committed in:** 1e787bd (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations.

## User Setup Required
None - no external service configuration required. Convex deployment completed automatically.

## Next Phase Readiness
- Full data pipeline ready for Plan 02 (Canvas UI) to consume: todayEntriesProvider streams entries, EntryRepository handles writes
- Search infrastructure ready for Plan 03: searchEntries query with full-text search and date range filtering
- speech_to_text dependency pre-installed for Plan 02 voice input

## Self-Check: PASSED

All 7 key files verified present on disk. Both task commits (279d996, 1e787bd) verified in git log.

---
*Phase: 02-daily-canvas*
*Completed: 2026-03-03*
