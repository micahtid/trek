# Project Research Summary

**Project:** Intern Growth Vault
**Domain:** Flutter mobile app — AI-driven professional journaling and accomplishment tracking for tech interns
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH

## Executive Summary

The Intern Growth Vault is a category-creating product: a mobile journaling app designed specifically for 10–12 week tech internships that combines automatic activity capture (Google Calendar events, GitHub commits) with AI-driven specificity questioning (Gemini) to generate resume-ready vault entries. No competitor does this. BragBook and BragDoc are the closest comparisons but require manual logging, target senior professionals, and lack the event-triggered conversational AI that is this product's core differentiator. The recommended approach is Flutter + Convex + firebase_ai (Gemini), using a reactive subscription architecture where Convex's real-time WebSocket queries eliminate polling, and Convex's scheduler handles all AI nudging and weekly archival asynchronously.

Two critical non-obvious discoveries shaped the stack. First, `google_generative_ai` is deprecated — all AI calls must go through `firebase_ai ^3.8.0`. Second, Convex Auth does not support Flutter; auth requires a custom OIDC bridge using `google_sign_in` to obtain a Google ID token passed to `convexClient.setAuthWithRefresh()`, with a custom JWT provider configured in `auth.config.ts`. These are not optional complications — they are architectural requirements that must be resolved in the first phase or they will block everything downstream.

The key risk is the interconnected dependency chain: push notifications trigger the core reflection loop, which requires Calendar integration, which requires Google OAuth, which requires Convex auth. If any link breaks, the entire product differentiator collapses. A secondary risk is the multi-account Google OAuth requirement for Calendar integration — `google_sign_in` only supports one account at a time, requiring a separate OAuth 2.0 flow for secondary Calendar accounts. This must be prototyped and validated in Phase 1 before Calendar-dependent features are built, because recovering from the wrong architecture choice is expensive.

## Key Findings

### Recommended Stack

The stack is well-defined with high confidence on all core technologies. Flutter 3.41.2 (Dart SDK ^3.8.1 — constrained by `convex_flutter ^3.0.1`) with Riverpod 3.x for state management is the correct foundation. Riverpod's `StreamProvider` is a natural fit for Convex's real-time query subscriptions. `go_router ^17.1.0` (Flutter team-maintained) handles guarded routes, nested shell navigation (Daily / Workspace / Vault bottom nav), and deep links from push notifications. Data modeling uses `freezed ^3.2.5` with `json_serializable` for type-safe domain objects, all generated via `build_runner`.

The auth and integration layer is more complex. Google Calendar uses `googleapis ^16.0.0` bridged to `google_sign_in ^7.2.0` via `extension_google_sign_in_as_googleapis_auth ^3.0.0` — this three-package chain is the only correct Flutter approach (using `googleapis_auth` directly is explicitly documented as wrong for Flutter). GitHub API uses `dio ^5.9.1` with auth interceptors for the GitHub REST API. Push notifications require both `firebase_messaging ^16.1.1` (FCM delivery) and `flutter_local_notifications ^20.1.0` (display and local scheduling). Subscriptions use `purchases_flutter ^9.12.3` (RevenueCat) to avoid DIY server-side receipt validation.

**Core technologies:**
- `convex_flutter ^3.0.1`: Reactive backend — real-time subscriptions, serverless functions, scheduler, file storage
- `firebase_ai ^3.8.0`: Gemini AI (replaces deprecated `google_generative_ai`; requires `firebase_core`)
- `firebase_messaging ^16.1.1`: FCM push notifications — the trigger for the entire reflection UX loop
- `flutter_riverpod ^3.2.1`: State management — `StreamProvider` wraps Convex subscriptions naturally
- `go_router ^17.1.0`: Declarative routing with auth guards and notification deep links
- `google_sign_in ^7.2.0` + `extension_google_sign_in_as_googleapis_auth ^3.0.0` + `googleapis ^16.0.0`: Google OAuth + Calendar API chain
- `dio ^5.9.1`: GitHub REST API client with interceptors
- `purchases_flutter ^9.12.3`: RevenueCat subscription management
- `freezed ^3.2.5` + `json_serializable ^6.13.0`: Immutable domain models with JSON serialization
- `flutter_secure_storage ^10.0.0`: Keychain/encrypted storage for OAuth tokens and credentials

**Avoid:**
- `google_generative_ai` — deprecated by Google, API key in client, no future updates
- `googleapis_auth` directly in Flutter — package docs say not to use it in Flutter
- Convex Auth library (`@convex-dev/auth`) — React/React Native only, not Flutter
- `shared_preferences` for credentials — stores in plaintext
- Background polling for Calendar/GitHub — battery-intensive; use FCM-triggered fetch instead

### Expected Features

Research identified a clear market gap: no competitor combines automatic activity capture with AI specificity drilling for the intern-specific use case. The five-pillar structured reflection framework (Key Learnings, Mistakes, Next Steps, Questions, What I Built Today) transforms journaling from diary entries into career documentation. The critical dependency chain is: Google OAuth → Calendar integration → event-triggered push notifications → AI follow-up questioning. All four must work for the core product loop to deliver value.

**Must have (table stakes — v1):**
- Google OAuth sign in — gates everything; no auth = no app
- Google Calendar integration — removes blank canvas; auto-populates meeting skeleton
- Daily canvas dashboard with meeting skeleton — core daily UX surface
- Manual entry creation with five-pillar framework — structured professional reflection
- AI follow-up questioning via Gemini — the core differentiator; without this it's just another journal
- Event-triggered push notifications — the trigger that starts the reflection habit
- Voice-to-text input — frictionless post-meeting capture before memory fades
- Weekly workspace with AI vault archival — validates the "your data compounds" promise
- Permanent queryable vault with full-text search — makes data feel valuable and retrievable
- Data export (CSV) — trust signal that intern owns their data permanently
- Subscription management — gates AI features; required before any monetization
- Automated skill tagging — proof of value accumulation

**Should have (competitive differentiation — v1.x after validation):**
- GitHub commit/PR auto-import — developer-specific proof of work without copy-pasting
- Photo capture (whiteboard, screenshots) — captures visual artifacts text cannot
- AI gap detection — "you had 6 meetings but only logged 2" personalized nudging
- AI vault query companion — conversational natural language vault search (subscription-gated)
- Weekly accomplishment overview — emotional engagement, combats imposter syndrome

**Defer (v2+):**
- Resume bullet point generation — needs 10–12 weeks of vault data; cannot validate until first interns complete a cycle
- Multi-account Google Calendar — edge case; validate single account first
- Excel export — minor variation after core CSV export proven
- Web application — explicitly out of scope; mobile-first validates the concept

**Anti-features to avoid building:**
- Social/sharing feed — destroys honest reflection; controlled export of polished bullets is the right answer
- Company/HR admin dashboards — changes the trust model completely; interns won't journal honestly if employer can read it
- Gamification/streaks — streak anxiety creates low-quality one-word entries; milestone celebrations for rich entries instead
- Mood tracking — dilutes the career-growth focus; five-pillar framework captures this implicitly

### Architecture Approach

The architecture is a reactive feature-first Flutter app backed by Convex's serverless platform. Flutter UI reads from Riverpod `StreamProvider`s that wrap Convex real-time query subscriptions via WebSocket — database changes auto-push to subscribed clients without polling. All business logic lives in Convex: queries (read-only, reactive), mutations (transactional reads/writes with scheduling), and actions (serverless functions for external API calls — Gemini, Calendar, GitHub, FCM). The Convex scheduler is the engine for the nudging loop: mutations write intent records to the DB and schedule actions atomically, ensuring nudges are never silently dropped if an AI call fails.

**Major components:**
1. Flutter UI layer — screens (Widgets) read from Riverpod providers; no business logic in widgets
2. Riverpod ViewModels — async state, commands exposed to views, Convex subscription wrappers
3. Feature Repositories — transform raw Convex JSON into typed Dart domain models; thin API wrapper over `ConvexClient`
4. `ConvexClient` singleton — single WebSocket connection; handles auth token refresh automatically
5. Convex Queries — reactive TypeScript functions; auto-rerun when DB data changes; push new results via WebSocket
6. Convex Mutations — transactional DB writes with atomic scheduling; the gateway for all state changes
7. Convex Actions — serverless functions; the only place external APIs (Gemini, Calendar, GitHub, FCM) are called
8. Convex Scheduler — `runAfter` / `crons` for nudge delivery and weekly archival
9. `go_router` — auth-guarded routing with deep links from push notification payloads

The project structure is feature-first under `lib/features/` (auth, canvas, capture, integrations, vault, ai_companion, subscription) with shared providers for cross-feature state (auth state, user profile). Convex backend mirrors this with thin TypeScript wrapper files and business logic in `convex/model/`.

**Build order is enforced by dependencies:**
Schema → Auth → ConvexClient + Riverpod setup → Daily canvas (full stack smoke test) → Capture inputs → Integrations → AI nudging → Push notifications → Weekly archival → Vault UI → Subscription gating

### Critical Pitfalls

1. **AI calls directly from Flutter client or from Convex mutations** — Mutations cannot call actions (Convex will throw). All Gemini calls must go through Convex Actions triggered by mutations via `ctx.scheduler.runAfter()`. The mutation writes a pending-intent record first, then schedules the action — ensuring intent is never lost if the AI call fails. Avoid this pattern from the first action written.

2. **Multi-account Google OAuth for Calendar** — `google_sign_in` supports only one Google account at a time; signing in with a second account overwrites the first session and logs the user out. The fix requires separating identity auth (`google_sign_in`) from resource auth (a separate OAuth 2.0 flow for Calendar-specific secondary accounts). This must be prototyped before building any Calendar-dependent features — recovery after the fact is expensive.

3. **Nested array document design in Convex** — Storing all week's entries in a single document as nested arrays creates query pain at scale (updates require full document rewrites, tag search requires full table scans, pagination is impossible). Schema must use normalized documents from day one: one document per entry with `weekId` foreign key, one WeekSummary document per week. Add `userId`, `weekId`, and `tags` indexes before the first data write.

4. **Push notifications silently fail for force-quit iOS apps** — Apple blocks FCM messages to force-quit apps. This is a platform constraint, not a bug. The core UX loop must treat push as best-effort and implement a pull-based catch-up: on every app open, check for Calendar events that occurred since last check and surface missed reflection opportunities. Design this fallback in the same phase as push implementation.

5. **FCM token rotation not synced** — Push tokens rotate silently. Register `FirebaseMessaging.instance.onTokenRefresh` listener on first launch and re-sync token to Convex on every app open. Without this, notification delivery rates decline invisibly week over week with no errors in logs.

6. **Gemini API quota changes** — Google changed quotas unexpectedly in December 2025. Every Gemini call must have exponential backoff with jitter, failed intent records in the DB (enabled by mutation-first pattern), and a feature flag in Convex to disable specific AI operations without a release. Use Gemini Flash for routine nudging, Gemini Pro only for resume generation.

7. **App Store rejection for subscription** — Apple requires a visible "Restore Purchases" button and subscription terms displayed before purchase. Free-tier features must be fully accessible without blocking paywall prompts. Review Apple/Google subscription guidelines before writing any paywall code.

## Implications for Roadmap

Based on research, the build order is dictated by hard dependencies: Convex auth must work before any user-scoped data exists; daily canvas must work before any AI features have data to act on; integrations must work before push notifications have events to trigger; archival must accumulate before vault query has data to search. The suggested phase structure follows this dependency chain.

### Phase 1: Foundation and Auth

**Rationale:** Every feature downstream requires a working Convex backend with auth and a Flutter app that can communicate with it. The Convex-Flutter auth bridge (custom OIDC JWT provider) is the highest-risk, least-documented integration in the stack. Proving it works early de-risks everything else. The multi-account Google OAuth architecture for Calendar must be prototyped and validated here before Calendar-dependent features are built on top of a broken foundation.

**Delivers:** Working Flutter app with Google OAuth sign-in, Convex auth configured, `ConvexClient` initialized, Riverpod providers wired, `go_router` auth guards active, feature folder structure in place, `flutter_secure_storage` for token persistence.

**Addresses:** Google OAuth sign-in (table stakes), security (per-user data isolation), offline graceful degradation (Convex reconnection).

**Avoids:** Multi-account OAuth architecture mistake (prototype secondary account flow here), API keys in Flutter client (establish all-secrets-in-Convex-env-vars rule from day one), schema design without indexes (define full Convex schema before first data write).

**Research flag:** Needs deep research — underdocumented Convex-Flutter OIDC bridge; multi-account Google OAuth is non-trivial.

### Phase 2: Daily Canvas (Core UX Loop)

**Rationale:** This phase is the full stack smoke test. Entry creation exercises the complete request flow: Flutter → Repository → ConvexClient → Convex mutation → reactive query → subscription → Riverpod StreamProvider → Widget rebuild. Getting this right validates the entire architectural pattern before building on top of it. Voice-to-text and the five-pillar framework belong here because they are part of entry creation, not separate features.

**Delivers:** Daily canvas dashboard with entry list, manual entry creation with five-pillar framework, voice-to-text capture, full-text search, automated skill tagging (Gemini action), full-text Convex search, basic timeline view.

**Addresses:** Daily canvas (P1), manual entry creation (P1), voice-to-text (P1), automated skill tagging (P2 in features matrix but naturally fits here), full-text search (P1).

**Avoids:** Business logic in Convex query/mutation wrappers (establish `convex/model/` pattern here), `.collect()` on unbounded queries (use `withIndex` from the start), photo compression on main thread (use isolate from first upload).

**Research flag:** Standard patterns — Riverpod + Convex subscription is well-documented; voice-to-text is a mature Flutter plugin.

### Phase 3: Google Calendar Integration and Push Notifications

**Rationale:** Calendar integration is the product's first major differentiator — it removes the blank canvas problem. Push notifications are the trigger for the entire reflection habit loop. These two are tightly coupled (Calendar event detected → event ends → push notification fires) and must be built together. The event-triggered nudge is what separates this from a generic journaling app.

**Delivers:** Google Calendar read integration (daily meeting skeleton auto-populated), Calendar event sync stored in Convex, FCM device token registration with rotation listener, event-triggered push notifications (fires after Calendar event ends), push notification deep links to relevant entry, pull-based catch-up for missed nudges on app open.

**Addresses:** Google Calendar integration (P1), event-triggered push notifications (P1), daily canvas dashboard with Calendar skeleton (completes P1).

**Avoids:** iOS force-quit push notification silent failure (build pull-based catch-up here, not later), FCM token rotation (register `onTokenRefresh` listener alongside initial registration), OAuth tokens stored in Flutter client (Calendar refresh tokens go to Convex DB server-side), Calendar scopes requested incrementally (not upfront at login).

**Research flag:** Needs research — Calendar OAuth scope incremental request flow; FCM v1 API integration with Convex actions; iOS APNs provisioning specifics.

### Phase 4: AI Follow-Up Questioning (Core Differentiator)

**Rationale:** This is the product's identity. Without AI-driven specificity drilling, the app is just another journaling tool. It belongs in its own phase after Calendar integration because the AI questioning is triggered by Calendar events and entry creation — both of which must exist first. The mutation-first pattern for Gemini calls must be established here and enforced as the project standard.

**Delivers:** Gemini AI integration via Convex actions, multi-turn specificity questioning after entry creation, AI follow-up questions saved to DB and pushed to device via push notification, Gemini quota handling (exponential backoff, intent records, retry scheduling), feature flag for AI degradation, Gemini Flash for nudging vs Pro for heavier tasks.

**Addresses:** AI follow-up questioning (P1), AI gap detection foundation (P2 — Calendar vs logged entries comparison).

**Avoids:** Calling Gemini from Flutter client (never — all AI through Convex actions), calling actions from mutations directly (always use `ctx.scheduler.runAfter`), Gemini quota exhaustion without retry (implement backoff before first real user), hardcoded Gemini model version (configurable via Convex environment variable).

**Research flag:** Needs research — Gemini 2.5 Flash prompt engineering for specificity drilling; Convex action retry patterns; rate limit handling at scale.

### Phase 5: GitHub Integration

**Rationale:** GitHub integration adds developer-specific proof of work and is the second major automatic capture source. It is deferred until Calendar + AI are working so the core loop is validated first. The rate limiting and caching architecture must be designed before building the UI against the API.

**Delivers:** GitHub commit/PR auto-import, activity displayed in daily canvas alongside Calendar events, GitHub data cached in Convex (max one fetch per 15 min per user), rate limit header reading with proactive backoff, ETag conditional requests.

**Addresses:** GitHub commit/PR integration (P2).

**Avoids:** GitHub rate limiting (implement caching layer before building UI), GitHub OAuth client secret in Flutter client (use PKCE or server-side token exchange).

**Research flag:** Standard patterns — GitHub REST API is well-documented; caching in Convex is straightforward.

### Phase 6: Weekly Vault Archival

**Rationale:** The weekly archival cycle is the mechanism that transforms raw daily notes into a permanent, queryable career record. It requires entry creation (Phase 2) and Gemini AI (Phase 4) to already exist. The cron-triggered batch processing pattern (fan out per-user to avoid action timeouts) must be used from day one — not as a scaling optimization later.

**Delivers:** Weekly workspace view, Convex cron job (Sunday night archival), batched per-user archival actions, Gemini weekly summary generation, WeekSummary documents written to vault, raw entries marked as archived, weekly accomplishment overview (positive tone framing), archival idempotency (safe to run twice).

**Addresses:** Weekly vault archival + AI formatting (P1), permanent queryable vault (P1), weekly accomplishment overview (P2).

**Avoids:** Single-action processing of all users (always fan out to per-user scheduled actions), sending raw entries to Gemini for resume generation (use weekly summaries as context — not raw entries, to avoid token limits), non-idempotent archival (duplicate vault entries on retry).

**Research flag:** Needs research — Convex cron + fan-out action pattern at scale; Gemini context window management for weekly summaries.

### Phase 7: Subscription Management

**Rationale:** Subscription gating must be implemented before any AI features are promoted as paid, and before any App Store submission. It belongs here — after the AI features it gates are working — so the paywall screens have real features to gate. Both client-side UI gating and server-side Convex mutation gating are required (never trust client-only gating).

**Delivers:** RevenueCat integration, subscription paywall with terms displayed, "Restore Purchases" button in settings, entitlement checking in every paid Convex action (server-side, not UI-only), free-tier features fully accessible without subscription prompts, sandbox subscription lifecycle testing.

**Addresses:** Subscription management (P1), data export CSV (trust signal — free tier).

**Avoids:** Client-only subscription gating (always validate server-side in Convex), App Store rejection (Restore Purchases, terms display, no blocking paywall for free-tier access), RevenueCat entitlements vs raw product IDs (use entitlements for cross-platform consistency).

**Research flag:** Needs research — Apple App Store subscription guideline checklist; RevenueCat webhook configuration for Convex.

### Phase 8: Vault Query and AI Companion

**Rationale:** The AI vault companion (conversational natural language search over career data) is the highest-value subscription feature but requires substantial vault data to deliver value. It must come after weeks of archival are working. This is the payoff that justifies the daily logging habit — interns can ask "show me everything I learned about Kubernetes" and get a curated answer from their own career record.

**Delivers:** AI vault query companion screen (subscription-gated), conversational vault search via Gemini RAG over WeekSummary documents, photo capture (image_picker + Convex file storage + Gemini vision for description extraction), AI gap detection (Calendar events vs logged entries comparison), timeline view for vault history.

**Addresses:** AI vault query companion (P2), photo capture (P2), AI gap detection (P2), timeline view (P2).

**Avoids:** Fetching all vault entries into Gemini context (send WeekSummary documents, not raw entries), image uploads without compression (compress to ≤500KB on a Dart isolate before uploading), full vault scan queries (use indexed queries with `withIndex` on `userId` + `weekId`).

**Research flag:** Needs research — RAG implementation over Convex documents with Gemini; image compression strategy for Flutter.

### Phase Ordering Rationale

- **Auth before everything:** Convex validates every query/mutation against user identity; no auth = no user-scoped data.
- **Canvas before integrations:** The full stack pattern (Flutter → ConvexClient → reactive query → Widget) must be proven before layering integrations on top.
- **Calendar + Push together:** They are causally linked — the event is the trigger for the notification. Separating them would require revisiting both in the same feature review.
- **AI after Calendar:** AI follow-up questioning is triggered by events and acts on entry data; both must exist first.
- **GitHub after AI:** GitHub is a differentiator but the core loop (Calendar → push → AI questioning) validates the product concept. GitHub extends the concept rather than enabling it.
- **Archival after AI:** Weekly summaries need Gemini to generate them; Gemini integration must be stable first.
- **Subscription before store:** Gating infrastructure must be ready before any App Store submission, and after the features it gates exist.
- **Vault companion last:** Requires accumulated archival data; the most valuable feature, but also the most data-dependent.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1 (Auth):** Convex-Flutter OIDC bridge is underdocumented; multi-account Google OAuth is non-obvious and recovery is expensive.
- **Phase 3 (Calendar + Push):** FCM v1 API + Convex action integration; iOS APNs provisioning in CI/CD; Calendar OAuth incremental scope requests.
- **Phase 4 (AI Questioning):** Gemini prompt engineering for specificity drilling; Convex action retry patterns with scheduler.
- **Phase 6 (Weekly Archival):** Convex cron fan-out pattern; Gemini context management for batched summaries.
- **Phase 7 (Subscription):** Apple App Store subscription compliance checklist; RevenueCat webhook setup.
- **Phase 8 (Vault Companion):** RAG architecture over Convex document store with Gemini.

Phases with standard patterns (skip research-phase):
- **Phase 2 (Daily Canvas):** Riverpod + Convex subscription is well-documented; voice-to-text is a mature Flutter plugin; five-pillar form is a standard Flutter form.
- **Phase 5 (GitHub):** GitHub REST API is comprehensively documented; Convex caching pattern is established by this point.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core packages verified on pub.dev with exact versions. Two critical surprises (`google_generative_ai` deprecated; Convex Auth no Flutter support) are confirmed against official docs. Only uncertainties: Syncfusion license requirements (LOW — use `excel` package instead to avoid) and RevenueCat pricing cut (not blocking for architecture). |
| Features | MEDIUM | Competitor analysis based on live site review (BragBook, BragDoc, WorkSaga, Day One) — MEDIUM confidence. Market gap assessment is well-supported. Feature dependencies and anti-features are high-confidence logical analysis. Push notification retention data from third-party source. |
| Architecture | MEDIUM-HIGH | Flutter architecture patterns from official docs (HIGH). Convex-specific patterns from official Convex docs (HIGH). Convex + Flutter integration examples are sparse (MEDIUM) — official Convex docs don't have Flutter-specific examples; patterns inferred from React Native examples and `convex_flutter` README. |
| Pitfalls | MEDIUM-HIGH | Core technical pitfalls verified against official docs (Convex mutation constraints, FCM iOS force-quit behavior, GitHub rate limit headers). Multi-account OAuth issue confirmed via Flutter GitHub issue tracker. Gemini quota change confirmed via multiple community reports (December 2025). App Store subscription requirements from RevenueCat official docs. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Convex-Flutter OIDC integration:** No single end-to-end official guide exists. The pattern (pass `google_sign_in` `idToken` to `setAuthWithRefresh`) is documented in pieces across Convex docs and `convex_flutter` README. Budget extra time and prototype this first in Phase 1.
- **Secondary Google account Calendar OAuth:** Flutter ecosystem limitation is confirmed but the correct implementation approach (separate OAuth 2.0 flow) needs a working prototype before committing to architecture. Use `oauth2` package or a webview-based flow; validate token isolation between accounts.
- **Gemini Flash vs Pro cost/quality tradeoffs for nudging:** Research confirms Flash is cheaper and faster; optimal prompt engineering for specificity drilling (2–3 follow-up questions that don't feel like interrogation) needs empirical testing. Defer to Phase 4 research.
- **Convex subscription cost at scale:** Free Starter tier (1M calls/month) is cited as sufficient for MVP. The per-connection and per-function-call cost model at 1k+ users needs validation before scaling. Not a Phase 1 concern.
- **Export format decision:** Syncfusion license requirement confirmed but complex. Use the `excel` (MIT-licensed) package as the default to avoid registration. Validate `excel` package produces valid `.xlsx` files for the vault export use case.

## Sources

### Primary (HIGH confidence)
- [pub.dev: convex_flutter](https://pub.dev/packages/convex_flutter) — version 3.0.1, Dart >=3.8.1, Flutter auth integration
- [Convex Auth docs](https://docs.convex.dev/auth/convex-auth) — Flutter not supported by Convex Auth
- [Convex Custom JWT Provider](https://docs.convex.dev/auth/advanced/custom-jwt) — OIDC bridge pattern for non-React clients
- [Firebase: Migrate from google_generative_ai](https://firebase.google.com/docs/ai-logic/migrate-from-google-ai-client-sdks) — `google_generative_ai` deprecation, migration to `firebase_ai`
- [Convex functions documentation](https://docs.convex.dev/functions) — query/mutation/action constraints, mutation-first scheduling pattern
- [Convex best practices](https://docs.convex.dev/understanding/best-practices/) — thin wrappers, model layer, no business logic in handlers
- [Convex scheduled functions](https://docs.convex.dev/scheduling/scheduled-functions) — `runAfter`, cron definitions, transactional scheduling
- [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide) — feature-first structure, ViewModel pattern
- [Firebase Cloud Messaging Flutter](https://firebase.flutter.dev/docs/messaging/overview/) — iOS force-quit behavior, token refresh
- [GitHub REST API Rate Limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) — 5,000 req/hr, ETag conditional requests
- [RevenueCat Flutter Integration](https://www.revenuecat.com/docs/getting-started/installation/flutter) — Restore Purchases requirement, entitlements
- [Google Calendar API Authorization](https://developers.google.com/calendar/api/guides/auth) — incremental scope request best practice
- [Flutter Security for Google APIs](https://docs.flutter.dev/data-and-backend/google-apis) — service account risk, user-delegated OAuth

### Secondary (MEDIUM confidence)
- [BragBook](https://bragbook.io/), [BragDoc](https://www.bragdoc.ai/), [WorkSaga](https://worksaga.app/) — competitor feature analysis (reviewed 2026-02-28)
- [Day One features](https://dayoneapp.com/features/) — table stakes journaling feature baseline
- [Google OAuth Multiple Accounts Flutter — GitHub Issue #121199](https://github.com/flutter/flutter/issues/121199) — `google_sign_in` single-account limitation
- [Gemini API Quota Changes — Community Reports, December 2025](https://www.aifreeapi.com/en/posts/gemini-api-pricing-and-quotas) — production quota disruptions
- [10 Essential Tips for New Convex Developers — Schemets](https://www.schemets.com/blog/10-convex-developer-tips-pitfalls-productivity) — type safety, nested data pitfalls
- [Flutter project structure (feature-first)](https://codewithandrea.com/articles/flutter-project-structure/) — community consensus on feature-first layout
- [Mastering Push Notifications in Flutter 2025](https://medium.com/@AlexCodeX/mastering-push-notifications-in-flutter-a-complete-2025-guide-to-firebase-cloud-messaging-fcm-589e1e16e144) — FCM token refresh, iOS simulator limitation

### Tertiary (LOW confidence)
- [AI journaling app comparison — reflection.app](https://www.reflection.app/blog/ai-journaling-apps-compared) — market overview, single source
- [Journaling app market overview — betterup.com](https://www.betterup.com/blog/journaling-apps) — marketing content, directional only
- [Push notification retention stats — businessofapps.com](https://www.businessofapps.com/marketplace/push-notifications/research/push-notifications-statistics/) — retention data, methodology unclear

---
*Research completed: 2026-02-28*
*Ready for roadmap: yes*
