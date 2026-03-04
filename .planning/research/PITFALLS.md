# Pitfalls Research

**Domain:** Flutter mobile app with Convex backend, Gemini AI, Google OAuth, Calendar/GitHub API integrations, push notifications, voice-to-text, photo uploads, weekly archival, and subscription management
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH (WebSearch verified against official docs for most claims; Convex+Flutter combination has limited community post-mortems due to recency)

---

## Critical Pitfalls

### Pitfall 1: Calling Convex Actions Directly From the Client for AI Nudging

**What goes wrong:**
The proactive AI nudging flow (Calendar event detected -> call Gemini -> send push notification) gets implemented as a client-side action call. Actions invoked directly from the client are executed immediately in parallel without ordering guarantees, and if the action fails mid-way (e.g., Gemini API timeout), there is no record that the intent was ever captured. The nudge is silently dropped.

**Why it happens:**
Developers reach for `ctx.runAction()` or call the action from the Flutter client because it feels like the direct path from "event detected" to "call AI." The mutation-first pattern is non-obvious until you've hit the failure mode.

**How to avoid:**
Always follow Convex's mutation-first pattern: the Flutter client calls a mutation that writes the pending-nudge intent to the database, then the mutation schedules an action. This way, if the action fails, the intent record remains and retry logic can act on it. Never trigger AI API calls directly from the client.

```
Client -> mutation (writes PendingNudge to DB) -> schedules action
Action -> calls Gemini API -> sends push notification -> marks PendingNudge as complete
```

**Warning signs:**
- AI nudges occasionally disappear with no error shown to the user
- No database record of which nudges were attempted vs. completed
- Action logs show success but notification was never received

**Phase to address:**
AI Nudging / Push Notification phase — establish this pattern in the very first action you write and enforce it as the project standard before building the full nudging pipeline.

---

### Pitfall 2: Multiple Google Accounts for Calendar Are Not Natively Supported by `google_sign_in`

**What goes wrong:**
The project requires users to attach additional Google accounts for Calendar integration (separate from their sign-in account). The `google_sign_in` Flutter package only maintains one authenticated account at a time. Attempting to sign in with a second account overwrites the first session, logging the user out of the app.

**Why it happens:**
The Flutter OAuth ecosystem treats Google Sign-In as a single-account flow. The multi-account requirement in the PROJECT.md ("Attach additional Google accounts for Calendar integration") is architecturally different from single-account OAuth and requires a separate approach that the main auth package does not provide.

**How to avoid:**
Separate auth-for-login from auth-for-Calendar-scopes at the architecture level. Use `google_sign_in` for identity/auth, and implement a separate OAuth 2.0 flow using `googleapis_auth` or `oauth2` package specifically for Calendar API access on secondary accounts. Store the resulting access tokens + refresh tokens in Convex against the user record, keyed by Google account email. Refresh tokens separately per account.

**Warning signs:**
- User signs into Calendar with a second account and is immediately logged out of the app
- `google_sign_in.currentUser` becomes null after a Calendar account attach attempt
- Refresh token for auth account disappears after Calendar account auth

**Phase to address:**
Google OAuth + Calendar Integration phase — must be prototyped and validated before building any Calendar-dependent features, as the architecture decision affects how all tokens are stored and managed.

---

### Pitfall 3: Treating Convex as Pure NoSQL With Nested Arrays for Weekly Archival

**What goes wrong:**
Weekly vault data gets stored as deeply nested arrays within a single Convex document (e.g., `{ week: "2026-W09", entries: [{...}, {...}, ...] }`). This works fine in development but becomes painful when you need to update a single entry within a week, query across weeks by tag, or paginate vault results. Updating one entry requires reading the entire week document, splicing the array, and rewriting the whole document.

**Why it happens:**
NoSQL familiarity and the desire to "group a week together" leads to document-per-week thinking. Convex's document model supports nested arrays so it doesn't fail early — it just creates future pain.

**How to avoid:**
Design the schema from the start with normalized documents: one document per entry (with a `weekId` foreign key), one document per week summary. Add indexes on `userId`, `weekId`, and `tags` from day one. The weekly vault transition should create a WeekSummary document and update individual entry documents to mark them as archived — not bundle them all into one document.

**Warning signs:**
- Mutations that update a single entry require reading and rewriting an entire week's worth of data
- Timeline view queries require client-side filtering across large documents
- Tag search across vault history requires fetching all week documents and scanning arrays

**Phase to address:**
Database schema design — must be settled before writing the first mutation. Revisiting schema after data exists is a migration burden in any database.

---

### Pitfall 4: Push Notifications Silently Fail on iOS When App Is Force-Quit

**What goes wrong:**
The proactive nudging loop (Calendar event ends -> push notification -> intern reflects) is the core UX loop. On iOS, if the user has force-quit the app from the app switcher, background FCM messages stop being received until the app is manually reopened. The intern misses the nudge and the daily capture loop breaks.

**Why it happens:**
iOS restricts background execution for force-quit apps — this is an Apple platform constraint, not a bug in the integration. Developers test on simulators (which don't support push notifications properly) or only test happy paths where the app is backgrounded but not terminated.

**How to avoid:**
- Accept this as a platform constraint and design the UX around it: treat push notifications as "best effort" reminders, not guaranteed delivery
- Supplement push notifications with pull-based discovery: when the app is opened, check for any Calendar events that occurred since the last check and surface missed reflection opportunities
- On Android, document that force-quit from device settings similarly stops messages
- Never test push notifications on iOS simulators — physical device only

**Warning signs:**
- QA finds notifications work inconsistently between test sessions
- iOS users in beta testing report "never seeing" some notifications
- Notification delivery rate drops significantly vs. open rate

**Phase to address:**
Push Notification integration phase — design the fallback (pull-based catch-up on app open) in the same phase as the push notification implementation, not as a later fix.

---

### Pitfall 5: Gemini API Quota Changes Break Production Unexpectedly

**What goes wrong:**
The app ships with AI nudging running on Gemini's free tier or with a fixed quota assumption. On December 7, 2025, Google announced significant quota adjustments that caught many developers off-guard with unexpected 429 errors disrupting production applications. The proactive nudging feature — the app's core differentiator — goes dark with no graceful degradation.

**Why it happens:**
Developers set quota limits during development and don't build quota-aware retry logic or graceful degradation paths because the feature "always works" in testing with low volume.

**How to avoid:**
- Implement exponential backoff with jitter on all Gemini API calls (treat 429 as recoverable)
- Store the pending nudge intent in Convex (via mutation-first pattern above) so failed AI calls can be retried via scheduled functions
- Gate AI features behind a feature flag in Convex so you can disable specific AI operations without a release if quotas are hit
- Monitor Gemini API usage via Google Cloud dashboard and set budget alerts
- Use Gemini Flash (cheaper, faster) for routine nudging; reserve Gemini Pro for resume bullet generation

**Warning signs:**
- Convex action logs showing 429 responses from Gemini
- AI nudging stops appearing for some users but not others (quota exhaustion mid-day)
- No retry record in the database for failed nudges

**Phase to address:**
AI integration phase — implement quota handling before shipping any AI feature to real users. The retry/graceful-degradation infrastructure is not optional.

---

### Pitfall 6: FCM Token Rotation Not Synced to Convex

**What goes wrong:**
Push notification tokens (FCM/APNs) rotate over time. If the app only registers the token on first install and never updates it in Convex, push notifications start failing silently for a growing percentage of users as their tokens rotate. There is no error from FCM — the message is just lost.

**Why it happens:**
The initial implementation registers the token at signup and it works. Token rotation is invisible during development (tokens are stable in dev environments). The bug only surfaces weeks or months after launch when token staleness accumulates.

**How to avoid:**
Listen to `FirebaseMessaging.instance.onTokenRefresh` stream and trigger a Convex mutation to update the stored token whenever it changes. Also re-sync the token on each app launch as a defensive measure, since the previous token may have been invalidated while the app was dormant.

**Warning signs:**
- Push notification delivery rate declines week-over-week despite stable user activity
- Users who haven't opened the app for 2+ weeks stop receiving nudges
- No errors in Convex action logs (FCM silently drops to stale tokens)

**Phase to address:**
Push Notification integration phase — implement token refresh listener alongside the initial token registration. Do not defer this to a "reliability pass."

---

### Pitfall 7: App Store Review Rejection for Subscription Flow

**What goes wrong:**
The subscription implementation (free database + paid AI) gets rejected by Apple/Google during App Store review because:
- There is no "Restore Purchases" button visible to users
- Subscription terms are not displayed before purchase
- Users cannot access data they created on the free tier without being coerced into a subscription screen

**Why it happens:**
Subscription flow edge cases (restore, term display, data access without subscription) are not tested until App Store submission. Both Apple and Google have strict guidelines that differ in details.

**How to avoid:**
- Add a "Restore Purchases" option accessible from settings — this is mandatory for Apple
- Display subscription terms and pricing clearly before the purchase flow initiates
- Ensure all free-tier features (data access, export) remain fully accessible without subscription prompts that block the UI
- Test the full subscription lifecycle on a sandbox/test account before submission, including: purchase, cancel, restore, and re-subscribe flows
- Use RevenueCat entitlements (not raw product IDs) to gate features so the same logic works across iOS and Android

**Warning signs:**
- Subscription screen shows pricing but no link to subscription terms
- Settings screen has no "Restore Purchases" option
- Free-tier users see modal dialogs blocking data access until they subscribe

**Phase to address:**
Subscription Management phase — review Apple App Store and Google Play subscription guidelines before writing any paywall code.

---

### Pitfall 8: GitHub API Rate Limiting Breaks Activity Skeleton for Active Users

**What goes wrong:**
Active interns (who commit frequently) trigger GitHub API polling that exhausts the 5,000 requests/hour limit. The activity skeleton that is supposed to show "commits, branches, PRs" shows nothing for the rest of the hour, breaking the core daily dashboard. Secondary rate limits (80 content-generating requests/minute) are hit even earlier if the sync logic is poorly batched.

**Why it happens:**
During development, one test user makes infrequent API calls so rate limits are never encountered. When multiple active users sync simultaneously (e.g., after a 9am standup where everyone pushed commits), rate limits are hit.

**How to avoid:**
- Cache GitHub data in Convex after each fetch — do not re-fetch if data is less than N minutes old
- Implement exponential backoff with jitter on GitHub API calls
- Never poll GitHub more than once per 15 minutes per user
- Use GitHub's conditional requests (ETag / `If-None-Modified` headers) to avoid counting unchanged data against the rate limit
- Store the rate limit headers (`X-RateLimit-Remaining`, `X-RateLimit-Reset`) from each response and back off proactively before hitting 0

**Warning signs:**
- GitHub activity section shows empty for periods during the day
- Convex action logs show 403 or 429 responses from GitHub API
- Rate limit errors correlate with time periods when many users are active

**Phase to address:**
GitHub Integration phase — implement caching and rate limit handling before building the activity skeleton UI. Do not build the UI against an uncached API.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip Convex schema definition, use schemaless documents | Faster early iteration | No type safety, cast-to-`any` in client code, migration pain when shape changes | Never — define schema before first data write |
| Frontend-only subscription gating (hide UI without server check) | Simple to implement | Users bypass paywalls by calling mutations directly; security failure | Never — always validate subscription status in Convex mutations |
| Store FCM token at install only, never refresh | Single registration call | Silent notification failures accumulate over weeks | Never — token refresh listener costs 5 lines |
| Bundle all week entries into one Convex document | Feels like natural grouping | Query and update pain at scale, difficult to paginate or filter by tag | Never for primary data — fine for summary/aggregate documents only |
| Call Gemini directly from Flutter client (skip Convex action) | One fewer round-trip | Exposes API key in client, no retry/audit trail, violates Convex architecture | Never — all AI calls must go through Convex actions |
| Use `any` types for Convex query results in Flutter | Faster to skip type wiring | Breaks refactor safety, eliminates Convex's main DX advantage | Never — generate types from Convex schema |
| Hardcode Gemini model version (e.g., `gemini-pro`) | Simple | Model deprecations break the app silently when Google retires the version | Never — make model version configurable in Convex environment variables |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Google OAuth (auth) | Using `google_sign_in` for both app login AND secondary Calendar accounts | Separate identity auth (`google_sign_in`) from resource auth (custom OAuth 2.0 flow via `googleapis_auth` for Calendar-specific accounts) |
| Google Calendar API | Requesting all Calendar scopes upfront at login | Request Calendar scopes incrementally when the user explicitly connects their calendar — reduces friction and App Store review risk |
| GitHub API | Polling on every app open | Cache in Convex, respect rate limit headers, max one fetch per 15 minutes per user |
| Gemini API | Calling from Flutter client directly | Route all Gemini calls through Convex actions; never expose API key in client |
| FCM (push) | Registering token at install only | Sync token on every app launch and listen to `onTokenRefresh` |
| RevenueCat / IAP | Gating features on client-side entitlement state alone | Validate subscription status in every Convex mutation that touches a paid feature |
| Convex File Storage | Uploading images via HTTP action for large files | Use upload URL pattern for anything over 20MB; generate URL via mutation (short lifetime — use within 1 hour) |
| iOS Push Notifications | Testing on simulator | Physical device only; simulators do not support APNs |
| Speech-to-Text | Assuming it works offline | `speech_to_text` package uses device/cloud recognition (requires network on many Android devices); test on physical device early; build a fallback text input path |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No Convex indexes on `userId`, `weekId`, `tags` | Vault queries slow down as data grows; timeline view lags | Add indexes in schema definition before first write | At ~500 entries per user |
| Fetching all vault entries to search client-side | Search feels instant in dev (few entries), slow in production | Use Convex's indexed queries with `withIndex`; implement server-side search | At ~100 vault entries |
| Image uploads without client-side compression | Photos from modern phones are 5-10MB; upload takes 30+ seconds on average mobile connection | Compress to ≤500KB before upload using `flutter_image_compress` on a background isolate | Every upload — visible immediately |
| Compressing images on the main thread | UI freezes during compression | Run compression in a Dart isolate or use the native-bridge packages that offload automatically | Every image, immediately noticeable |
| Sequential Convex mutation calls in a loop | Batching 7 day entries creates 7 serial network round-trips | Batch insertions in a single mutation; pass a list to the mutation function | With any loop > 1 |
| Sending full internship vault as Gemini context for resume generation | Resume generation context can exceed 100K tokens; cost spikes; accuracy degrades | Summarize vault data incrementally (weekly summaries already in schema); send summaries, not raw entries, to Gemini | At ~10 weeks of detailed daily entries |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing Gemini API key in Flutter client code | Key scraped from APK; unlimited billed API usage by attacker | All Gemini calls go through Convex actions server-side; API key stored in Convex environment variables, never shipped in the app |
| Exposing GitHub OAuth client secret in Flutter client | OAuth flows can be hijacked; attacker impersonates the app | Use PKCE flow (no client secret needed for public clients); store any server-side tokens in Convex, never in Flutter |
| Frontend-only subscription gating | Users call paid Convex mutations without active subscription by decompiling the app | Every Convex mutation that touches AI features reads subscription status from the database; check entitlement in the mutation body, not just in the UI |
| Storing OAuth refresh tokens in Flutter's local storage unencrypted | Device compromise exposes all user's Google/GitHub tokens | Use `flutter_secure_storage` for all token storage; never use `SharedPreferences` for credentials |
| Not validating `userId` ownership in Convex mutations | User A can modify User B's data by passing a forged document ID | Every mutation reads `ctx.auth.getUserIdentity()` and verifies the document being modified belongs to the authenticated user |
| Shipping service account credentials in the APK for Calendar API | Credential compromise affects all users | Never use service accounts from a mobile client; use user-delegated OAuth tokens only |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Requesting microphone + camera + photo permissions at app launch | Users deny all permissions preemptively, breaking voice/photo features permanently | Request permissions at the moment the feature is first invoked; explain why the permission is needed in a pre-permission dialog |
| AI follow-up questions feel like interrogation rather than conversation | Interns stop entering reflections; churn | Limit to 2-3 follow-up questions per entry; frame them as suggestions ("Would you like to add...?"), not demands; always allow saving without answering |
| Weekly vault transition is opaque (no progress indication) | Users think the app is broken when archival takes time | Show a friendly "Wrapping up your week..." state; run archival as a Convex scheduled function triggered in advance of the week boundary |
| Push notification opens app to wrong screen | Intern taps notification, lands on home screen, loses context | Wire notification payload to `data.entryId` and deep-link directly to the relevant reflection entry |
| Subscription paywall appears during the first session | Interns don't understand the value yet; immediate uninstall | Gate AI features behind value demonstration; let user complete at least one full reflection → vault → summary cycle before showing paywall |
| Voice input has no visual feedback during recording | Users don't know if they're being heard | Show animated waveform or timer during active recording; show transcript in real time if the STT plugin supports streaming |

---

## "Looks Done But Isn't" Checklist

- [ ] **Google OAuth:** Token refresh is implemented — verify access token is refreshed before expiry and that Convex `setAuthWithRefresh` callback handles 401 responses without crashing
- [ ] **Push Notifications:** Token rotation handler is registered — verify `onTokenRefresh` listener is active and updates Convex on every rotation
- [ ] **Push Notifications iOS:** Tested on a physical device with APNs provisioning — simulator results are unreliable and do not represent production behavior
- [ ] **Push Notifications - Force Quit:** Pull-based catch-up on app open is implemented — verify missed nudges surface when the app is reopened after being force-quit
- [ ] **Subscription gating:** Server-side validation exists in Convex — verify that calling a paid mutation directly (bypassing UI) returns an authorization error
- [ ] **Gemini actions:** Retry/failure tracking exists — verify that a Gemini API failure writes a failed-attempt record to the database and schedules a retry
- [ ] **GitHub sync:** Rate limit headers are read and respected — verify the sync backs off when `X-RateLimit-Remaining` is low, not just after receiving a 429
- [ ] **Image upload:** Client-side compression runs before upload — verify a typical smartphone photo (8-12MP) is compressed before the upload URL request is made
- [ ] **Weekly archival:** Archival is idempotent — verify that running the archival function twice on the same week does not create duplicate vault entries
- [ ] **Speech-to-text:** Physical device tested — verify on a real Android and real iOS device; test what happens when network is unavailable (many STT implementations require network)
- [ ] **Calendar OAuth (secondary account):** Token storage is isolated per account — verify that attaching a second Calendar account does not invalidate the first account's tokens or the app's own auth session
- [ ] **Convex schema:** All `userId` indexes exist — verify `withIndex("by_userId", ...)` works on every user-scoped table before writing queries that will run in production

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Schema designed without indexes | MEDIUM | Add indexes in schema, deploy; existing data is automatically re-indexed by Convex (no migration script needed, but there is a one-time indexing cost) |
| Nested array document design for entries | HIGH | Write a migration script using Convex scheduled functions to read each week document, extract entries, write them as individual documents, delete the old document; requires careful coordination with live data |
| API key exposed in client | HIGH | Rotate key immediately in Google Cloud Console; audit for unauthorized usage; deploy new release with key removed from client code within hours |
| FCM tokens stale (notifications failing) | LOW | Deploy update with `onTokenRefresh` listener; tokens will self-heal as users open the app |
| Gemini quota exhausted | LOW | Enable retry queue (if mutation-first pattern was followed); switch to Gemini Flash for nudging to reduce token cost; notify users of temporary AI degradation if needed |
| Multi-account Calendar OAuth broken | HIGH | Requires architectural change to token storage model; must be caught in Phase 1 integration prototype — not recoverable cheaply after Calendar features are built |
| App Store rejection for subscription flow | MEDIUM | Add Restore Purchases button, update paywall UI with required disclosures, resubmit; typically 2-5 day re-review turnaround |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Convex mutation-first pattern for AI actions | AI Nudging / Action architecture phase | Code review: no Gemini calls exist outside Convex action functions; every action is triggered by a mutation that first writes intent to DB |
| Multiple Google accounts OAuth architecture | Google OAuth + Calendar Integration phase | Prototype test: attach second Google account without disrupting app auth session; confirm both tokens stored and refreshable independently |
| Nested array document design | Database schema design (pre-coding) | Schema review: every user-facing data type is its own table with foreign key indexes; no arrays of complex objects in documents |
| Push notification force-quit fallback | Push Notification phase | Test: force-quit app on iOS, trigger a Calendar event, reopen app — verify missed reflection appears |
| FCM token rotation | Push Notification phase | Test: manually invalidate FCM token and verify Convex document is updated within one app launch |
| Gemini quota handling + graceful degradation | AI integration phase (first Gemini call) | Test: mock a 429 response from Gemini and verify the intent record is retained in DB and retry is scheduled |
| GitHub rate limiting and caching | GitHub Integration phase | Test: exhaust rate limit in sandbox; verify app falls back to cached data gracefully with no empty states |
| Subscription server-side validation | Subscription Management phase | Security test: call a paid Convex mutation with a valid auth token but no active subscription — must return authorization error |
| App Store subscription flow compliance | Subscription Management phase (pre-submission) | Manual review against Apple Human Interface Guidelines subscription checklist before TestFlight submission |
| Image compression before upload | Photo Upload phase | Test: upload a raw 10MP photo and verify the file stored in Convex is under 800KB; verify UI does not freeze during compression |
| Speech-to-text physical device testing | Voice Input phase | Test matrix: real iOS device (online), real Android device (online), both devices with airplane mode — document behavior in each case |
| Security: API keys never in Flutter client | Architecture setup / first Convex action written | Audit: `flutter analyze` + manual grep for any API key strings in lib/; all secrets must be in Convex environment variables |

---

## Sources

- [Convex Actions — Official Docs](https://docs.convex.dev/functions/actions) — action timeout, no auto-retry, mutation-first pattern (HIGH confidence)
- [Convex Mutations — Official Docs](https://docs.convex.dev/functions/mutation-functions) — transactional guarantees, scheduling from mutations (HIGH confidence)
- [10 Essential Tips for New Convex Developers — Schemets](https://www.schemets.com/blog/10-convex-developer-tips-pitfalls-productivity) — type safety, query/mutation misuse, nested data, frontend-only security, index delay (MEDIUM confidence)
- [Convex File Storage — Official Docs](https://docs.convex.dev/file-storage/upload-files) — 20MB HTTP action limit, 2-minute upload URL timeout, 1-hour URL expiry (HIGH confidence)
- [Convex Scheduled Functions — Official Docs](https://docs.convex.dev/scheduling/scheduled-functions) — transactional scheduling, cron limitations (HIGH confidence)
- [Flutter Firebase Cloud Messaging — Official Docs](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages) — iOS force-quit behavior, background handler ordering, foreground notification display (HIGH confidence)
- [Mastering Push Notifications in Flutter 2025 — Medium/AlexCodeX](https://medium.com/@AlexCodeX/mastering-push-notifications-in-flutter-a-complete-2025-guide-to-firebase-cloud-messaging-fcm-589e1e16e144) — FCM token refresh, iOS simulator limitation, foreground display requirement (MEDIUM confidence)
- [GitHub REST API Rate Limits — Official Docs](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api) — 5,000 req/hr authenticated limit, secondary rate limits, ETag conditional requests (HIGH confidence)
- [Google OAuth Multiple Accounts Flutter — GitHub Issue #121199](https://github.com/flutter/flutter/issues/121199) — `google_sign_in` single-account limitation (MEDIUM confidence)
- [Gemini API Quota Changes — Community Reports, December 2025](https://www.aifreeapi.com/en/posts/gemini-api-pricing-and-quotas) — production quota disruptions, 429 errors, Flash vs Pro cost optimization (MEDIUM confidence — multiple sources agree)
- [RevenueCat Flutter Integration — Official Docs](https://www.revenuecat.com/docs/getting-started/installation/flutter) — restore purchases requirement, entitlements vs product IDs, sandbox testing (HIGH confidence)
- [Google Calendar API Authorization — Official Docs](https://developers.google.com/calendar/api/guides/auth) — OAuth scope requirements, incremental scope request best practice (HIGH confidence)
- [Flutter Push Notifications Deep Dive: Custom Payloads — Vibe Studio](https://vibe-studio.ai/insights/flutter-push-notifications-deep-dive-custom-payloads) — payload size limits (4KB iOS, 2KB Android), deep-link routing (MEDIUM confidence)
- [speech_to_text Flutter Package — pub.dev](https://pub.dev/packages/speech_to_text) — platform limitations, offline behavior, iOS transcription reset bug (MEDIUM confidence)
- [Flutter Security for Google APIs — Official Flutter Docs](https://docs.flutter.dev/data-and-backend/google-apis) — service account credential risk, user-delegated OAuth requirement (HIGH confidence)

---
*Pitfalls research for: Flutter + Convex + Gemini AI intern growth tracking app*
*Researched: 2026-02-28*
