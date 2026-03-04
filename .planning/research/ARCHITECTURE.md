# Architecture Research

**Domain:** Flutter + Convex mobile app (intern growth tracking / professional knowledge base)
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH (Flutter architecture HIGH via official docs; Convex-Flutter integration MEDIUM due to limited Flutter-specific official examples)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MOBILE CLIENT (Flutter)                           │
├──────────────────┬──────────────────────┬───────────────────────────────┤
│   UI LAYER       │                      │                               │
│  ┌────────────┐  │   STATE LAYER        │   SERVICE LAYER               │
│  │  Screens   │  │  ┌───────────────┐   │  ┌────────────────────────┐   │
│  │ (Widgets)  │◄─┤  │   Riverpod    │   │  │  ConvexClient          │   │
│  └────────────┘  │  │   Providers   │◄──┤  │  (singleton, WebSocket)│   │
│  ┌────────────┐  │  │ (ViewModels)  │   │  └───────────┬────────────┘   │
│  │  Shared    │  │  └───────┬───────┘   │              │               │
│  │  Widgets   │  │          │           │  ┌───────────▼────────────┐   │
│  └────────────┘  │          ▼           │  │  Repositories          │   │
│                  │  ┌───────────────┐   │  │  (data transformation) │   │
│  NAVIGATION      │  │  Domain Models│   │  └────────────────────────┘   │
│  ┌────────────┐  │  └───────────────┘   │                               │
│  │  go_router │  │                      │  ┌────────────────────────┐   │
│  └────────────┘  │                      │  │  Platform Services      │   │
│                  │                      │  │  (FCM, Camera, Voice)  │   │
└──────────────────┴──────────────────────┴──┴────────────────────────────┘
                                   │ WebSocket (real-time) + HTTP
                    ┌──────────────▼───────────────────────────────────────┐
                    │                  CONVEX BACKEND                       │
                    ├──────────────┬───────────────────┬────────────────────┤
                    │  QUERIES     │   MUTATIONS       │   ACTIONS          │
                    │  (read-only, │   (transactional  │   (serverless,     │
                    │  reactive,   │   read/write)     │   external APIs)   │
                    │  subscribed) │                   │                    │
                    ├──────────────┴───────────────────┴────────────────────┤
                    │               CONVEX DATABASE                          │
                    │    (document-relational, ACID, reactive)               │
                    ├───────────────────────────────────────────────────────┤
                    │          CONVEX FILE STORAGE                           │
                    │    (photos, voice recordings, exports)                 │
                    ├───────────────────────────────────────────────────────┤
                    │          CONVEX SCHEDULER                              │
                    │    (runAfter / runAt / cron — push notification        │
                    │     triggers, weekly archival, AI nudging)             │
                    └───────────────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┼────────────────────────────────┐
                    │                EXTERNAL SERVICES                      │
                    │  ┌──────────────┐  ┌────────────┐  ┌─────────────┐   │
                    │  │ Google OAuth │  │ Google Cal │  │ GitHub API  │   │
                    │  └──────────────┘  └────────────┘  └─────────────┘   │
                    │  ┌──────────────┐  ┌────────────┐                     │
                    │  │ Gemini AI    │  │ FCM (push) │                     │
                    │  └──────────────┘  └────────────┘                     │
                    └───────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Screens (Views) | Render UI, handle gestures, no business logic | Flutter Widget classes, read from Providers |
| Riverpod Providers (ViewModels) | UI state, commands exposed to Views, async data | `AsyncNotifierProvider`, `StateNotifierProvider` |
| Domain Models | Plain Dart classes representing app entities | Immutable data classes, freezed package optional |
| Repositories | Transform raw Convex data into domain models; cache invalidation | Dart classes wrapping ConvexClient calls |
| ConvexClient | Singleton WebSocket connection to Convex backend | `convex_flutter` package, initialized once in main() |
| go_router | Declarative URL-based routing with auth guards | Route definitions; redirect on auth state change |
| Convex Queries | Read-only reactive functions; auto-rerun on DB change | TypeScript functions in `convex/` folder |
| Convex Mutations | Atomic transactions that read/write database | TypeScript functions; scheduling is transactional |
| Convex Actions | Serverless functions that call external APIs | TypeScript; calls Gemini, Google Cal, GitHub, FCM |
| Convex Scheduler | Deferred/periodic function execution | `ctx.scheduler.runAfter()`, `crons.weekly()` |
| Convex File Storage | Store photos and voice recordings | Upload URL generation → POST → save storageId |
| FCM (Firebase Cloud Messaging) | Deliver push notifications to device | Called from Convex Action via HTTP |

## Recommended Project Structure

```
lib/
├── main.dart                    # App entry, ConvexClient.initialize(), Riverpod ProviderScope
├── app.dart                     # MaterialApp.router, go_router config, theme
├── core/
│   ├── constants/               # App-wide constants (API URLs, config)
│   ├── errors/                  # Error types, ConvexError handling
│   ├── extensions/              # Dart extension methods
│   └── utils/                   # Formatters, helpers
├── routing/
│   ├── app_router.dart          # go_router definition, all routes
│   └── redirect_logic.dart      # Auth guard redirects
├── shared/
│   ├── widgets/                 # Common widgets used across features
│   └── providers/               # Cross-feature providers (auth state, user profile)
└── features/
    ├── auth/
    │   ├── data/
    │   │   └── auth_repository.dart     # Google OAuth token → Convex setAuth()
    │   ├── domain/
    │   │   └── user.dart                # User model
    │   └── presentation/
    │       ├── login_screen.dart
    │       └── auth_provider.dart       # Riverpod auth state
    ├── canvas/                          # Daily dashboard (core UX)
    │   ├── data/
    │   │   └── canvas_repository.dart   # Subscribe to daily entries
    │   ├── domain/
    │   │   └── daily_entry.dart
    │   └── presentation/
    │       ├── canvas_screen.dart
    │       └── canvas_provider.dart
    ├── capture/                         # Text, voice, photo input
    │   ├── data/
    │   │   └── capture_repository.dart  # File upload, mutation calls
    │   ├── domain/
    │   │   └── capture_entry.dart
    │   └── presentation/
    │       ├── capture_sheet.dart       # Bottom sheet for input
    │       └── capture_provider.dart
    ├── integrations/                    # Google Calendar + GitHub
    │   ├── data/
    │   │   └── integration_repository.dart
    │   ├── domain/
    │   │   └── activity_event.dart
    │   └── presentation/
    │       └── integration_settings_screen.dart
    ├── vault/                           # Weekly + long-term vault
    │   ├── data/
    │   │   └── vault_repository.dart
    │   ├── domain/
    │   │   └── vault_entry.dart
    │   └── presentation/
    │       ├── vault_screen.dart
    │       ├── timeline_screen.dart
    │       └── vault_provider.dart
    ├── ai_companion/                    # Subscription-gated AI query
    │   ├── data/
    │   │   └── ai_repository.dart
    │   └── presentation/
    │       └── companion_screen.dart
    └── subscription/                    # Paywall, subscription status
        ├── data/
        │   └── subscription_repository.dart
        └── presentation/
            └── paywall_screen.dart

convex/                                  # Convex backend (TypeScript)
├── schema.ts                            # Database schema (tables + indexes)
├── auth.config.ts                       # Google OAuth OIDC configuration
├── model/                               # Plain TS helper functions (business logic)
│   ├── entries.ts
│   ├── vault.ts
│   └── ai.ts
├── entries.ts                           # Thin query/mutation wrappers for entries
├── canvas.ts                            # Daily canvas queries
├── vault.ts                             # Vault archival mutations + queries
├── integrations/
│   ├── calendar.ts                      # Google Calendar action
│   └── github.ts                        # GitHub API action
├── ai/
│   ├── nudge.ts                         # Gemini nudging action
│   ├── summary.ts                       # Weekly summary action
│   └── resume.ts                        # Resume generation action
├── notifications/
│   └── push.ts                          # FCM push notification action
├── scheduler/
│   └── crons.ts                         # Weekly archival cron definitions
└── files.ts                             # File upload URL generation
```

### Structure Rationale

- **Feature-first under `lib/features/`:** All files for a given feature (data, domain, presentation) are co-located. The 2025 Flutter community consensus is that feature-first scales better than layer-first for medium-to-large apps. Developers working on "vault" don't need to jump between top-level `repositories/`, `providers/`, and `screens/` folders.
- **`convex/model/` for business logic:** Convex best practices state that most logic should be plain TypeScript functions, with query/mutation/action wrappers being thin. This keeps decorator functions short and testable logic in `model/`.
- **Thin `convex/*.ts` files:** Each top-level TypeScript file exposes the public API of a domain. Functions call into `model/` helpers. This mirrors the Flutter Repository pattern — thin API layer, logic elsewhere.
- **`shared/providers/`:** Auth state and user profile are needed across all features and don't belong inside any single feature folder.

## Architectural Patterns

### Pattern 1: Reactive Subscription via Convex + Riverpod Stream

**What:** Flutter UI subscribes to a Convex query. When database data changes, Convex re-runs the query and pushes the new result over WebSocket. Riverpod Provider wraps this subscription as a Dart Stream, triggering widget rebuilds automatically.

**When to use:** Any screen displaying live data — the daily canvas, vault entries, AI conversation state.

**Trade-offs:** Eliminates manual polling and cache invalidation. Adds WebSocket connection management complexity. Works only when online (matches the app's online-connected constraint).

**Example:**
```dart
// In canvas_provider.dart
final canvasProvider = StreamProvider.autoDispose<List<DailyEntry>>((ref) {
  final repo = ref.watch(canvasRepositoryProvider);
  return repo.watchTodayEntries(); // Returns a Stream backed by ConvexClient.subscribe()
});

// In canvas_repository.dart
Stream<List<DailyEntry>> watchTodayEntries() {
  final controller = StreamController<List<DailyEntry>>();
  final handle = ConvexClient.instance.subscribe(
    'canvas:getTodayEntries',
    {'userId': _userId},
    onResult: (data) => controller.add(_mapToDomainList(data)),
    onError: (e) => controller.addError(e),
  );
  // cancel handle when stream is cancelled
  return controller.stream;
}
```

```typescript
// In convex/canvas.ts
export const getTodayEntries = query({
  args: { userId: v.id('users') },
  handler: async (ctx, { userId }) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new ConvexError('Unauthenticated');
    return await ctx.db
      .query('entries')
      .withIndex('by_user_date', (q) => q.eq('userId', userId).eq('date', today()))
      .collect();
  },
});
```

### Pattern 2: Action-Scheduled Push Notification (Event-Driven Nudging)

**What:** A Convex mutation processes a new activity event (calendar meeting detected, commit found). Within the same transaction, it schedules a Convex Action to fire after a delay. The Action calls FCM to deliver a push notification. Because scheduling is transactional with the mutation, the notification fires if and only if the data write succeeded.

**When to use:** Every time the integration sync detects a new calendar event or GitHub commit. The delay (e.g., 15 minutes after event end) is configurable per notification type.

**Trade-offs:** Push notifications require a separate FCM project and device token management stored in Convex DB. Actions have no direct database access — they must call mutations to write back. Notification delivery is not guaranteed (device offline, OS throttling).

**Example:**
```typescript
// In convex/integrations/calendar.ts
export const syncCalendarEvent = mutation({
  args: { eventId: v.string(), userId: v.id('users'), endsAt: v.number() },
  handler: async (ctx, { eventId, userId, endsAt }) => {
    const id = await ctx.db.insert('calendar_events', { eventId, userId, endsAt });
    // Schedule nudge 10 minutes after the event ends — atomic with this mutation
    const delayMs = Math.max(0, endsAt - Date.now()) + 10 * 60 * 1000;
    await ctx.scheduler.runAfter(delayMs, internal.notifications.push.sendNudge, {
      userId,
      message: 'How did your meeting go?',
    });
    return id;
  },
});

// In convex/notifications/push.ts
export const sendNudge = internalAction({
  args: { userId: v.id('users'), message: v.string() },
  handler: async (ctx, { userId, message }) => {
    const token = await ctx.runQuery(internal.users.getDeviceToken, { userId });
    if (!token) return; // Device not registered
    await fetch('https://fcm.googleapis.com/v1/projects/.../messages:send', {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.FCM_SERVER_KEY}` },
      body: JSON.stringify({ message: { token, notification: { body: message } } }),
    });
  },
});
```

### Pattern 3: Weekly Vault Archival via Cron + Workflow

**What:** A Convex cron job fires every Sunday evening. It triggers an Action that loads the week's raw entries in batches (to avoid the 1000-document `collect()` limit), calls Gemini to generate a summary, and then writes the archived vault entry via mutation. Batching is required because entries may exceed the limit for active interns.

**When to use:** Weekly archival, AI summary generation, any time you need to process an unbounded set of documents and call external APIs.

**Trade-offs:** Cron jobs are statically defined at deploy time. For runtime-dynamic scheduling (per-user archival), use the `convex/crons` component which allows runtime registration. AI summary generation in an Action means failures don't roll back the week's raw data (only the archive mutation would roll back). Retry logic is needed.

**Example:**
```typescript
// In convex/scheduler/crons.ts
import { cronJobs } from 'convex/server';
import { internal } from './_generated/api';

const crons = cronJobs();

crons.weekly(
  'weekly-vault-archival',
  { dayOfWeek: 'sunday', hourUTC: 23, minuteUTC: 0 },
  internal.vault.archiveAllUsers,
);

export default crons;

// In convex/vault.ts (action — batched processing)
export const archiveAllUsers = internalAction({
  handler: async (ctx) => {
    let cursor = null;
    do {
      const page = await ctx.runQuery(internal.vault.getUsersPage, { cursor });
      for (const user of page.users) {
        await ctx.scheduler.runAfter(0, internal.vault.archiveUserWeek, {
          userId: user._id,
        });
      }
      cursor = page.nextCursor;
    } while (cursor);
  },
});
```

### Pattern 4: File Upload (Photos and Voice)

**What:** Three-step upload flow. Flutter requests an upload URL from Convex (mutation). Flutter sends the file bytes directly to that URL via HTTP POST. Flutter calls a second mutation with the returned `storageId` to persist the reference in the database.

**When to use:** Photo capture (whiteboard sketches), voice recording upload.

**Trade-offs:** Files are uploaded directly to Convex's storage, not through the WebSocket connection. This keeps binary data out of the real-time channel. The storageId must be saved immediately after upload or the file is orphaned.

**Example:**
```dart
// In capture_repository.dart
Future<String> uploadPhoto(File photo) async {
  // Step 1: Get upload URL
  final uploadUrl = await ConvexClient.instance.mutation(
    'files:generateUploadUrl', {},
  ) as String;

  // Step 2: POST file to upload URL
  final response = await http.post(
    Uri.parse(uploadUrl),
    headers: {'Content-Type': 'image/jpeg'},
    body: await photo.readAsBytes(),
  );
  final storageId = jsonDecode(response.body)['storageId'] as String;

  // Step 3: Save storageId to database
  await ConvexClient.instance.mutation(
    'entries:attachPhoto', {'storageId': storageId, 'entryId': _currentEntryId},
  );
  return storageId;
}
```

## Data Flow

### Request Flow: User Adds a Text Entry

```
User types reflection → CaptureScreen
    ↓
capture_provider.dart (ViewModel) — calls submitEntry command
    ↓
CaptureRepository.createEntry(text, pillar)
    ↓
ConvexClient.instance.mutation('entries:create', {...})
    ↓ (WebSocket RPC)
Convex mutation: entries:create — validates args, checks auth, writes to DB
    ↓ (atomic with scheduling)
ctx.scheduler.runAfter(300_000, internal.ai.nudge, {entryId, userId})
    ↓
Mutation returns success
    ↓
All subscribed queries depending on 'entries' table are re-run automatically
    ↓
canvas:getTodayEntries subscription fires → new result pushed via WebSocket
    ↓
canvasProvider Stream emits new List<DailyEntry>
    ↓
CanvasScreen widget rebuilds
```

### AI Nudging Flow: Gemini Follow-Up Question

```
Scheduled Action fires (5 min after entry created)
    ↓
internal.ai.nudge (Action) — reads entry via ctx.runQuery
    ↓
Calls Gemini API with entry text + system prompt asking for follow-up question
    ↓
Writes AI question back to DB via ctx.runMutation('ai:saveNudge', {question})
    ↓ (mutation triggers reactive update)
User's conversation provider Stream receives new AI message
    ↓
Push notification ALSO sent via FCM action (scheduled separately)
    ↓
User taps notification → app opens to CaptureScreen with AI question pre-loaded
```

### State Management

```
Auth State (Riverpod)
    ↓ (provides token to ConvexClient)
ConvexClient singleton — WebSocket connection open
    ↓ (subscription)
Repository.watchXxx() → Dart Stream
    ↓
StreamProvider (Riverpod) — wraps Stream
    ↓
Screen Widget — watches provider, rebuilds on emission
    ↓ (user action)
ViewModel.submitCommand() → Repository.create/update() → ConvexClient.mutation()
    ↓ (Convex re-runs affected queries)
Stream emits updated data → Widget rebuilds
```

### Key Data Flows

1. **Auth token propagation:** Google OAuth ID token (JWT) obtained on device → passed to `ConvexClient.instance.setAuthWithRefresh()` → auto-refreshed 60 seconds before expiry → included in all WebSocket messages to Convex → verified server-side via `ctx.auth.getUserIdentity()`.

2. **Integration sync (Calendar/GitHub):** User connects account in settings → OAuth tokens stored in Convex DB (encrypted via environment variable) → Convex Action polls Calendar/GitHub API on a cron schedule OR on-demand → inserts activity events into DB → subscription on canvas screen picks up new events → push notification nudge scheduled.

3. **Subscription gating:** Subscription status stored in Convex DB → Flutter reads status via subscribed query → Riverpod provider exposes `isSubscribed` flag → AI companion screen and resume generation use `ref.watch(subscriptionProvider)` to gate UI → Convex mutations/actions for AI features call `ctx.runQuery(internal.subscriptions.isActive)` to double-check server-side (never trust client-only gating).

4. **Weekly vault transition:** Cron fires Sunday night → batch Action reads week's entries per user → Gemini generates summary → mutation writes `vault_week` document → raw entries marked as archived → client subscription on vault screen shows new week entry.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Convex free tier is sufficient. Single deployment. All cron jobs run serially per user in the weekly archival. No pagination needed for most queries. |
| 1k-10k users | Weekly archival cron must batch users and use `ctx.scheduler.runAfter()` per-user to avoid timeouts. Add `withIndex()` on all queries. Monitor Convex function execution time limits. |
| 10k-100k users | Consider Convex Workpool component for parallel action execution with rate limiting. Gemini API rate limits become a constraint — queue AI calls. FCM batching for push notifications. |
| 100k+ users | Convex subscription cost scales with connections. Evaluate whether all screens need real-time subscriptions (canvas yes, vault history likely no — on-demand queries sufficient). |

### Scaling Priorities

1. **First bottleneck: Weekly archival Action timeouts.** Convex Actions have execution time limits. A naive "process all users in one action" fails at ~100+ users. Fix: fan out to per-user scheduled actions immediately (use the pattern in Pattern 3 above).

2. **Second bottleneck: Gemini API rate limits.** At scale, Sunday-night summary generation for thousands of users hits Gemini's rate limits simultaneously. Fix: spread archival over Sunday night window, add retry with backoff via Convex Workpool.

## Anti-Patterns

### Anti-Pattern 1: Calling ctx.runAction from Inside a Mutation

**What people do:** Call an action (e.g., Gemini AI call) directly inside a mutation to get AI results synchronously.

**Why it's wrong:** Mutations must be deterministic and transactional. Actions can make network requests, which would break transactional guarantees. Convex will error — mutations cannot call actions via `ctx.runAction`.

**Do this instead:** In the mutation, write to DB and schedule the action via `ctx.scheduler.runAfter(0, internal.ai.nudge, args)`. The action runs asynchronously and writes results back via its own mutation call.

### Anti-Pattern 2: Using .collect() on Unbounded Queries

**What people do:** `ctx.db.query('entries').collect()` to get all entries for a user, then filter in TypeScript.

**Why it's wrong:** Convex limits `.collect()` to 1024 documents. An active intern with months of daily entries will hit this. Also bypasses index efficiency.

**Do this instead:** Use `.withIndex()` to filter at the database level (e.g., by userId + date range). Use pagination with `.paginate()` for history views. Use `.filter()` only for small result sets.

### Anti-Pattern 3: Putting Business Logic in Convex Query/Mutation Wrappers

**What people do:** Write all business logic inline in the `query()` or `mutation()` handler function.

**Why it's wrong:** These handler functions cannot be easily unit-tested or reused across multiple API endpoints. The Convex best-practices guide explicitly recommends keeping wrappers thin.

**Do this instead:** Extract logic to plain TypeScript functions in `convex/model/`. Call model functions from the thin query/mutation/action wrappers.

### Anti-Pattern 4: Storing OAuth Tokens for Calendar/GitHub in Flutter Client State

**What people do:** Store the user's Google Calendar or GitHub OAuth tokens in Flutter's SharedPreferences or in-memory state, then call those APIs directly from Flutter.

**Why it's wrong:** Tokens are exposed in the client. The app can't schedule background API calls (e.g., the hourly calendar sync cron). Token refresh logic must be re-implemented on the client.

**Do this instead:** After OAuth consent on the client, send the refresh token to a Convex mutation to store it encrypted in the database. All Calendar/GitHub API calls happen server-side in Convex Actions. The client only sees the processed activity events, not raw API tokens.

### Anti-Pattern 5: Client-Only Subscription Gating

**What people do:** Check `isSubscribed` in the Flutter UI and conditionally show AI features. Assume this is sufficient.

**Why it's wrong:** A determined user can bypass client-side checks. Convex mutations/actions for AI features (Gemini calls cost money) must also check subscription status server-side.

**Do this instead:** Gate at two levels — Flutter UI hides the feature (for UX), AND every Convex action that calls Gemini calls `ctx.runQuery(internal.subscriptions.isActive, {userId})` before proceeding. Fail fast server-side with a descriptive error.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Google OAuth | Device-side OAuth flow (google_sign_in package) → ID token (JWT) → `ConvexClient.setAuthWithRefresh()` | Auth configured in `convex/auth.config.ts` as OIDC provider. Refresh token stored nowhere on client — ConvexClient handles refresh callbacks. |
| Google Calendar API | Convex Action calls Calendar API with stored OAuth token → inserts activity events into DB | Calendar OAuth refresh tokens stored encrypted in Convex DB. Action triggered by cron (hourly sync) or mutation scheduling. |
| GitHub API | Convex Action calls GitHub REST API with stored Personal Access Token or OAuth token → inserts commit/PR events | Similar storage pattern to Calendar. GitHub tokens are longer-lived; PAT is simpler than OAuth for v1. |
| Gemini AI | Convex Action only (actions can make HTTP calls, mutations cannot) → streaming response written back via mutation | API key in Convex environment variables. Rate limit awareness critical for weekly batch processing. |
| Firebase Cloud Messaging | Convex Action sends FCM REST API call with device token → delivers push to device | Device FCM token captured in Flutter on first launch and stored in Convex DB per user. Token refresh handled by FCM plugin. |
| Convex File Storage | 3-step upload: generateUploadUrl mutation → Flutter HTTP POST → attachFile mutation | Binary data never goes through WebSocket. storageId is a reference stored in the entry document. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Flutter Screen <-> ViewModel | Riverpod watch/read; commands (callbacks) | Never pass BuildContext into ViewModel. ViewModels are plain Dart classes. |
| ViewModel <-> Repository | Direct Dart method calls; returns Futures and Streams | Repository is injected via Riverpod provider, enabling test overrides. |
| Repository <-> ConvexClient | `ConvexClient.instance.query/mutation/subscribe()` | All calls are async. Subscribe returns a cancellable handle. Handle must be cancelled when Stream is disposed. |
| Convex Query/Mutation <-> Model layer | Plain TypeScript function calls | No async boundary here — model functions are pure TS. |
| Convex Mutation <-> Action | `ctx.scheduler.runAfter()` only — never direct call | This is an enforced Convex constraint, not a convention. Mutations calling actions directly will throw. |
| Convex Action <-> DB | `ctx.runQuery()` / `ctx.runMutation()` — must go through these wrappers | Actions cannot call `ctx.db` directly; they must delegate to query/mutation functions. |

## Build Order Implications

The architecture has clear dependency layers. Build in this order to avoid blocked work:

1. **Convex schema + auth configuration** — Everything else reads/writes to the database. Auth must work before any user-scoped query runs.
2. **ConvexClient initialization + Riverpod setup in Flutter** — The plumbing layer. Feature repositories cannot exist without this.
3. **Auth feature (Google OAuth)** — All other features require an authenticated user. go_router redirect guards depend on auth state.
4. **Core canvas feature (daily entry CRUD)** — The central UX loop. This exercises the full stack end-to-end: Flutter → Repository → ConvexClient → Convex mutation → reactive query → subscription → Riverpod → Widget.
5. **Capture inputs (text, then voice, then photo)** — Progressive complexity. Text is simplest (string mutation). Voice adds file upload. Photo adds file upload + camera permissions.
6. **Integrations (Calendar, GitHub)** — Convex Actions calling external APIs. Requires OAuth token storage pattern established in auth phase.
7. **AI nudging (Gemini)** — Requires scheduler pattern (from cron setup), Actions (from integration phase), and entry data to already exist.
8. **Push notifications (FCM)** — Requires Convex Actions and scheduler. FCM device token management is standalone but must come before nudges reach users.
9. **Weekly vault archival + AI summary** — Requires all entry data patterns, Gemini integration, and cron setup.
10. **Vault query UI + AI companion** — Reads from the archive written in step 9. AI companion calls Gemini from an Action.
11. **Subscription gating** — Applied as a layer on top of existing AI features. Subscription check added to existing Convex actions; paywall screen added to Flutter routing.

## Sources

- convex_flutter pub.dev package — https://pub.dev/packages/convex_flutter (HIGH confidence: official package)
- Flutter app architecture guide (official) — https://docs.flutter.dev/app-architecture/guide (HIGH confidence: official docs)
- Flutter architectural overview (official) — https://docs.flutter.dev/resources/architectural-overview (HIGH confidence: official docs)
- Convex functions documentation — https://docs.convex.dev/functions (HIGH confidence: official docs)
- Convex understanding / overview — https://docs.convex.dev/understanding/ (HIGH confidence: official docs)
- Convex best practices — https://docs.convex.dev/understanding/best-practices/ (HIGH confidence: official docs)
- Convex scheduled functions — https://docs.convex.dev/scheduling/scheduled-functions (HIGH confidence: official docs)
- Convex file storage — https://docs.convex.dev/file-storage (HIGH confidence: official docs)
- Convex auth documentation — https://docs.convex.dev/auth (HIGH confidence: official docs)
- Flutter project structure (feature-first) — https://codewithandrea.com/articles/flutter-project-structure/ (MEDIUM confidence: leading Flutter community author, Andrea Bizzotto)
- Flutter Riverpod vs BLoC 2025 comparison — https://flutterfever.com/flutter-bloc-vs-riverpod-vs-provider-2025/ (MEDIUM confidence: community article, cross-referenced with multiple sources)
- go_router package — https://pub.dev/packages/go_router (HIGH confidence: official Flutter team package)
- Convex Workpool component — https://www.convex.dev/components/workpool (MEDIUM confidence: official Convex component page)
- Firebase Cloud Messaging Flutter — https://firebase.flutter.dev/docs/messaging/overview/ (HIGH confidence: official FlutterFire docs)

---
*Architecture research for: Flutter + Convex mobile app (intern growth tracking)*
*Researched: 2026-02-28*
