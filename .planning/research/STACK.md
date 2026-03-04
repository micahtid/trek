# Stack Research

**Domain:** Flutter mobile app — intern growth tracker with AI, Google Calendar, GitHub, and Convex backend
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH (core stack HIGH, auth bridge MEDIUM, export LOW)

---

## Critical Pre-Read: Two Surprises Found During Research

1. **`google_generative_ai` is deprecated.** Google deprecated this package with Gemini 2.0 and redirected all developers to `firebase_ai`. Do NOT use `google_generative_ai`. Use `firebase_ai ^3.8.0` instead.

2. **Convex Auth does NOT officially support Flutter.** Convex Auth's docs explicitly state it supports "React web apps and React Native mobile apps." Flutter is not listed. The workaround is to use `google_sign_in` to get a Google ID token (JWT), then pass it to `convex_flutter`'s `setAuth()` method. This requires configuring a Custom JWT provider on the Convex backend. This is functional but underdocumented.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| Flutter | 3.41.2 (stable) | Cross-platform mobile UI framework | Project constraint. Dart SDK 3.11.0+ already in project scaffold. Current stable is 3.41.2 (Feb 11, 2026). | HIGH |
| Dart | ^3.8.1 (SDK) | Language | Ships with Flutter. `convex_flutter ^3.0.1` requires Dart SDK >=3.8.1, which is the binding constraint here. | HIGH |
| Convex | cloud backend | Reactive backend: database, serverless functions, real-time subscriptions | Project constraint. Strongly consistent, reactive, TypeScript-based. Queries auto-subscribe via WebSocket — interns see live data without polling. Free Starter tier (1M calls/month) is sufficient for MVP. | MEDIUM |
| convex_flutter | ^3.0.1 | Flutter SDK for Convex | Official Flutter client for Convex. Version 3.0.1 published 2026-02-24. Requires Dart >=3.8.1. Wraps Convex Rust core. Provides `ConvexClient`, queries, mutations, actions, and JWT-based auth via `setAuthWithRefresh()`. | HIGH |
| firebase_ai | ^3.8.0 | Gemini AI model calls | Replacement for the now-deprecated `google_generative_ai`. Published by Firebase (google.com). Version 3.8.0 published 2026-02-10. Requires `firebase_core`. API key never embedded in app code (server-side security). Supports Gemini 2.5 Flash and Gemini 3.1 Flash. | HIGH |
| firebase_core | ^3.x | Firebase project initialization | Required by `firebase_ai`. Also sets up the project for FCM push notifications — so initializing Firebase once covers both AI and push. | HIGH |
| firebase_messaging | ^16.1.1 | Push notifications (FCM) | Flutter Favorite. 1.67M downloads. Official FlutterFire plugin by firebase.google.com. Critical for the core UX loop (nudging interns after Calendar/GitHub events). Works on Android + iOS. Version 16.1.1 published ~Jan 2026. | HIGH |

### Authentication & Google Integration

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| google_sign_in | ^7.2.0 | Google OAuth sign-in | Official Flutter plugin (flutter.dev). Version 7.2.0 is current stable. v7 is a significant breaking-change rewrite from v6. Handles PKCE, scope management, and token refresh on Android + iOS. Google People API must be enabled (not the old Identity Toolkit). | HIGH |
| extension_google_sign_in_as_googleapis_auth | ^3.0.0 | Bridge: google_sign_in → googleapis | Official Flutter team package. Adds `authenticatedClient()` extension to `GoogleSignIn`, returning an `AuthClient` usable with any `googleapis` service. Without this, you cannot feed `google_sign_in` credentials to the `googleapis` Calendar package. Do NOT use `googleapis_auth` directly — its docs explicitly say "do not use with Flutter." | HIGH |
| googleapis | ^16.0.0 | Google Calendar API v3 client | Official auto-generated Google client library. Version 16.0.0 published Feb 2026. Import `package:googleapis/calendar/v3.dart` to call Calendar API. Use with `extension_google_sign_in_as_googleapis_auth` for auth. | HIGH |

**Auth flow for Convex (critical detail):**

Convex Auth only natively supports React/React Native. For Flutter, the pattern is:

1. User taps "Sign in with Google" → `google_sign_in` returns a `GoogleSignInAuthentication` with `idToken` (a JWT)
2. Pass `idToken` to `convexClient.setAuthWithRefresh(() => getIdToken())` — Convex validates against Google's OIDC endpoint
3. On the Convex backend (`auth.config.ts`), configure a custom OIDC provider with `applicationID`, `issuer: "https://accounts.google.com"`, and Google's JWKS URL
4. Convex validates all subsequent requests server-side

This is documented in pieces across Convex docs (Custom JWT Provider) and the `convex_flutter` README. There is no single end-to-end Flutter + Google guide from Convex. **Budget extra setup time for this integration.**

### State Management

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| flutter_riverpod | ^3.2.1 | App-wide state management | Riverpod 3.x (stable as of Sep 2025, current 3.2.1 as of Feb 2026) is the best-maintained reactive state solution for Flutter. Better than BLoC for a solo/small-team app: less boilerplate, compile-time safety, context-free providers. Convex real-time subscriptions are async streams — Riverpod's `StreamProvider` is a natural fit. | HIGH |
| riverpod_annotation | ^4.0.2 | Code-gen annotations for Riverpod | Required by `riverpod_generator`. Provides `@riverpod` annotation. | HIGH |
| riverpod_generator | ^4.0.3 (dev) | Generate providers from annotations | Eliminates manual provider wiring. Published Feb 2026 (24 days ago). Avoids wrong-provider-type mistakes. Recommended by Riverpod 3.x docs when using code gen already (which we are, with Freezed). | HIGH |

### Data Modeling & Serialization

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| freezed | ^3.2.5 | Immutable data classes, union types | Flutter Favorite. 1.72M weekly downloads. Generates `copyWith()`, `==`, `toString()`, and JSON serialization. Essential for modeling `Entry`, `VaultItem`, `Skill` domain objects without mutation bugs. Published Feb 2026 (24 days ago). | HIGH |
| freezed_annotation | ^3.x | Annotations for freezed codegen | Required by `freezed`. | HIGH |
| json_serializable | ^6.13.0 (dev) | JSON encode/decode | Official Google package. Works alongside `freezed`. Use for serializing data passed between Flutter and Convex (Convex functions return JSON). Version 6.13.0 published Feb 2026. | HIGH |
| json_annotation | ^4.x | Annotations for json_serializable | Required by `json_serializable`. | HIGH |
| build_runner | ^2.x (dev) | Code generation runner | Runs `freezed` + `riverpod_generator` + `json_serializable`. One `dart run build_runner watch` covers all generators. | HIGH |

### Navigation

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| go_router | ^17.1.0 | Declarative navigation | Official Flutter team package (flutter.dev). Version 17.1.0 published Feb 2026. Declarative, URL-aware, deep-link capable. The app needs guarded routes (unauthenticated → login, authenticated → dashboard), nested shell routes for bottom nav (Daily / Workspace / Vault), and deep links from push notifications. `go_router` handles all of this cleanly. | HIGH |

### Networking

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| dio | ^5.9.1 | HTTP client for GitHub API | GitHub API is a REST API not covered by `googleapis`. `dio` provides interceptors (attach auth tokens automatically), retry logic, and clean error handling. Version 5.9.1 published Jan 2026. 8.24k likes. Use `dio` for GitHub API calls only — Convex and Google Calendar have their own SDKs. | HIGH |

### Media & Input

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| speech_to_text | ^7.3.0 | Voice-to-text input | Standard Flutter STT plugin. Uses device OS speech recognition (no cloud cost). Android SDK 21+, iOS 12+. Version 7.3.0 published ~Aug 2025. Requires `NSSpeechRecognitionUsageDescription` in iOS Info.plist. Suitable for short voice notes (not continuous dictation). | MEDIUM |
| image_picker | ^1.2.1 | Photo upload (whiteboard captures) | Official Flutter plugin (flutter.dev). 7.68k likes, 2.22M downloads. Version 1.2.1 published ~Nov 2025. Picks from gallery or camera. Returns `XFile`. Requires iOS privacy keys for camera and photo library. | HIGH |

### Notifications (Local Scheduling)

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| flutter_local_notifications | ^20.1.0 | Local notification scheduling | Used alongside `firebase_messaging` for displaying rich in-app notifications and scheduling future notifications. Version 20.1.0 published ~Feb 2026. Requires Flutter SDK >=3.22. FCM handles remote delivery; `flutter_local_notifications` handles custom display and local scheduling. | HIGH |

### Storage

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| flutter_secure_storage | ^10.0.0 | Persist auth tokens, user credentials | Keychain (iOS) + Encrypted Shared Preferences/Tink (Android). Version 10.0.0 published Dec 2025, a significant rewrite (Jetpack Security library deprecated). Stores Google OAuth refresh tokens, GitHub PAT (if used), and Convex session data between app restarts. | HIGH |

### Subscriptions & Monetization

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| purchases_flutter | ^9.12.3 | In-app subscription management | RevenueCat SDK. Wraps StoreKit + Google Play Billing in one API. Handles receipt validation server-side (no DIY validation). Version 9.12.3 published Feb 2026 (45 hours ago). Subscription status tracking, webhooks, analytics, and entitlement checking built in. Vastly simpler than `in_app_purchase` for subscription logic. Requires iOS 13.0+, Android SDK 21+. | MEDIUM |

### Export

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| syncfusion_flutter_xlsio | ^32.2.7 | Export vault data to Excel/CSV | Generates real `.xlsx` files (not CSVs written as text). Version 32.2.7 published Feb 2026. **Requires Syncfusion Community License** (free for revenue under $1M/yr, requires registration). Alternative: `excel` package (pub.dev) is fully open-source but less full-featured. | LOW |

---

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| flutter_lints | ^6.0.0 | Official lint rules | Already in scaffold. Keep version in sync with Flutter SDK. |
| riverpod_lint | ^4.x | Riverpod-specific lint rules | Catches common Riverpod mistakes (missing `ref.watch` vs `ref.read`, etc.). Works with `custom_lint`. |
| custom_lint | ^0.7.x | Plugin host for riverpod_lint | Required to run `riverpod_lint`. |
| Firebase CLI | global install | Initialize Firebase project, configure `google-services.json` + `GoogleService-Info.plist` | `npm install -g firebase-tools`. Required before any Firebase/FCM/AI work. |
| FlutterFire CLI | global install | Configure Flutter app to Firebase project | `dart pub global activate flutterfire_cli` then `flutterfire configure`. Generates `firebase_options.dart`. |
| Convex CLI | npm global | Deploy and manage Convex backend functions | `npm install -g convex`. Used to set env vars (`npx convex env set`), run `npx convex dev` locally. |

---

## Installation

```bash
# --- Flutter packages ---

# Core runtime
flutter pub add convex_flutter
flutter pub add firebase_core
flutter pub add firebase_ai
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications

# Auth & Google integrations
flutter pub add google_sign_in
flutter pub add extension_google_sign_in_as_googleapis_auth
flutter pub add googleapis

# State management
flutter pub add flutter_riverpod riverpod_annotation

# Navigation
flutter pub add go_router

# Networking
flutter pub add dio

# Data modeling & serialization (runtime annotations)
flutter pub add freezed_annotation json_annotation

# Media & input
flutter pub add speech_to_text image_picker

# Storage
flutter pub add flutter_secure_storage

# Subscriptions
flutter pub add purchases_flutter

# Export (choose one)
flutter pub add syncfusion_flutter_xlsio   # requires Syncfusion license
# OR
flutter pub add excel                       # fully open-source alternative

# --- Dev dependencies ---
flutter pub add --dev build_runner
flutter pub add --dev freezed
flutter pub add --dev json_serializable
flutter pub add --dev riverpod_generator
flutter pub add --dev custom_lint
flutter pub add --dev riverpod_lint
flutter pub add --dev flutter_lints
```

**Resulting pubspec.yaml (key sections):**

```yaml
environment:
  sdk: ^3.8.1   # constrained by convex_flutter requirement

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Backend
  convex_flutter: ^3.0.1

  # Firebase (AI + Push)
  firebase_core: ^3.0.0
  firebase_ai: ^3.8.0
  firebase_messaging: ^16.1.1
  flutter_local_notifications: ^20.1.0

  # Auth & Google APIs
  google_sign_in: ^7.2.0
  extension_google_sign_in_as_googleapis_auth: ^3.0.0
  googleapis: ^16.0.0

  # State
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^4.0.2

  # Navigation
  go_router: ^17.1.0

  # Networking (GitHub API)
  dio: ^5.9.1

  # Data modeling
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

  # Media
  speech_to_text: ^7.3.0
  image_picker: ^1.2.1

  # Storage
  flutter_secure_storage: ^10.0.0

  # Subscriptions
  purchases_flutter: ^9.12.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.0
  freezed: ^3.2.5
  json_serializable: ^6.13.0
  riverpod_generator: ^4.0.3
  custom_lint: ^0.7.0
  riverpod_lint: ^4.0.0
```

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `firebase_ai ^3.8.0` | `google_generative_ai ^0.4.7` | **Deprecated by Google.** No future updates. API key embedded in app code (security risk). Migrate path well-documented. |
| `convex_flutter ^3.0.1` | HTTP polling to Convex REST API | Convex's strength is real-time reactive queries over WebSocket. Using REST defeats the purpose. The official client wraps the Rust core for reliability. |
| `flutter_riverpod ^3.2.1` | `flutter_bloc` | BLoC is excellent but adds significant boilerplate for a solo/small-team project. Riverpod's `StreamProvider` is a natural fit for Convex real-time subscriptions. BLoC is better for large teams where strict event/state separation matters. |
| `flutter_riverpod ^3.2.1` | Provider (package) | Provider is Riverpod's predecessor. Riverpod fixes Provider's core issues (context dependency, testability). Do not use Provider for new projects. |
| `purchases_flutter ^9.12.3` | `in_app_purchase ^3.x` | `in_app_purchase` is lower-level and requires DIY server-side receipt validation. For a subscription app, RevenueCat handles validation, entitlement checking, and analytics out of the box. Worth the RevenueCat cut (~12% of IAP revenue) to avoid rolling subscription logic. |
| `go_router ^17.1.0` | `auto_route` | Both are good. `go_router` is maintained by the Flutter team itself, reducing risk of abandonment. No meaningful capability gap for this app. |
| `dio ^5.9.1` | `http ^1.x` | `http` is fine for simple one-off requests. GitHub API needs auth interceptors, retry logic, and error handling patterns. `dio` provides these without custom middleware. |
| `syncfusion_flutter_xlsio` | `excel` (pub.dev package) | `excel` is MIT-licensed, no registration required. Produces valid `.xlsx` files. Fewer chart/formula features than Syncfusion but adequate for tabular data export. Use `excel` if Syncfusion licensing is a barrier. |
| `googleapis ^16.0.0` + `extension_google_sign_in_as_googleapis_auth ^3.0.0` | Custom REST calls to Calendar API | Official client handles pagination, serialization, and auth refresh. No meaningful downside to using the official library. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `google_generative_ai` | Deprecated by Google with Gemini 2.0. No future updates planned. Embeds API key in app code (security issue). Docs now redirect to `firebase_ai`. | `firebase_ai ^3.8.0` |
| `googleapis_auth` (directly in Flutter) | Package's own documentation says "Do NOT use this package with a Flutter application." Auth flow is incompatible with Flutter's platform plugins. | `extension_google_sign_in_as_googleapis_auth` (the official bridge) |
| Convex Auth library (`@convex-dev/auth`) | Only supports React web and React Native. Flutter is not supported. Using it will result in broken OAuth flow on mobile. | `google_sign_in` + Custom JWT provider config on Convex backend (pass `idToken` to `setAuthWithRefresh`) |
| `provider` package | Predecessor to Riverpod. Context-dependent, harder to test, not suitable for new projects per Riverpod author's own recommendation. | `flutter_riverpod ^3.2.1` |
| Firebase Firestore / Realtime Database | Stack constraint is Convex. Adding Firebase database creates a second backend with competing real-time sync mechanisms. Firebase is only used here for AI (firebase_ai) and push (FCM). | Convex for all database/backend logic |
| `flutter_bloc` / BLoC | Not wrong, but higher boilerplate than Riverpod for a solo-dev project. The BLoC pattern's benefits (strict event/state separation) are more valuable on large teams. | `flutter_riverpod` |
| `shared_preferences` for sensitive data | Stores data in plain text on Android, unencrypted SharedPreferences. OAuth tokens and GitHub credentials must not be stored here. | `flutter_secure_storage ^10.0.0` |
| Background polling for Calendar/GitHub | Battery-intensive, unreliable on iOS (background execution limits). The app's architecture should detect events via push notification (FCM) and then fetch, not continuously poll. | FCM-triggered fetch via `firebase_messaging` |

---

## Stack Patterns by Variant

**For the Convex → Flutter auth flow (Google OAuth):**
- Use `google_sign_in` to get an OIDC `idToken` (not the `accessToken`)
- Pass `idToken` to `convexClient.setAuthWithRefresh(fetchToken)`
- Configure Convex backend `auth.config.ts` with `{ type: "customJwt", applicationID: "<your-google-client-id>", domain: "https://accounts.google.com" }`
- The `applicationID` must match your Google Cloud OAuth client ID — this prevents token theft across applications

**For the Calendar API (read completed events):**
- Request `CalendarApi.calendarReadonlyScope` when signing in via `google_sign_in`
- Use `extension_google_sign_in_as_googleapis_auth` to get `AuthClient`
- Call `CalendarApi(authClient).events.list(calendarId, timeMin: today, showDeleted: false)`
- Store fetched events in Convex via a mutation (not in-memory) so they persist and can trigger AI analysis

**For the GitHub API (read commits/PRs):**
- GitHub API does not require OAuth for public repos (rate-limited at 60 req/hr unauthenticated)
- For private repos or higher limits, use GitHub Personal Access Token (PAT) stored in `flutter_secure_storage`
- Use `dio` with a base interceptor that attaches `Authorization: token $pat`
- GitHub REST API v3 endpoints: `/users/{user}/events`, `/repos/{owner}/{repo}/commits`, `/repos/{owner}/{repo}/pulls`

**For AI probing (conversational follow-up questions):**
- Use `firebase_ai` with Gemini 2.5 Flash (cost-efficient)
- Maintain conversation history in a `List<Content>` for multi-turn sessions
- Run AI actions as Convex Actions (server-side), not from the Flutter client directly — keeps prompts and model selection server-controlled, enables rate limiting per user

**For subscription gating:**
- Use `purchases_flutter` to check `CustomerInfo.entitlements.active` on app launch and route appropriately
- Gate AI features (nudging, vault query, resume gen) behind entitlement check in Convex functions as well as client-side — server-side check prevents API abuse by unsubscribed users

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `convex_flutter ^3.0.1` | Dart SDK >=3.8.1 | This is the binding SDK constraint. Forces Flutter >=3.32.x. The project scaffold has `sdk: ^3.11.0` — update to `^3.8.1` to satisfy convex_flutter. |
| `firebase_ai ^3.8.0` | `firebase_core ^3.x` | Both must be from the same Firebase BoM generation. Update all firebase_* packages together. |
| `firebase_messaging ^16.1.1` | `firebase_core ^3.x` | Same Firebase BoM constraint. |
| `flutter_riverpod ^3.2.1` | `riverpod_annotation ^4.0.2`, `riverpod_generator ^4.0.3` | Must use matching major versions. Riverpod 3.x is NOT compatible with `riverpod_generator ^2.x` or `^3.x`. |
| `freezed ^3.2.5` | `build_runner ^2.x` | Freezed 3.x works with build_runner 2.x. No special version pinning needed. |
| `flutter_local_notifications ^20.1.0` | Flutter SDK >=3.22 | Flutter 3.41.2 satisfies this. If downgrading Flutter, check this requirement. |
| `google_sign_in ^7.2.0` | `extension_google_sign_in_as_googleapis_auth ^3.0.0` | The extension package targets `google_sign_in ^7.x`. Do not mix with `google_sign_in ^6.x`. |
| `purchases_flutter ^9.12.3` | iOS 13.0+, Android SDK 21+ | iOS 13 is the minimum — check deployment target in Xcode. |

---

## Sources

- [pub.dev: convex_flutter](https://pub.dev/packages/convex_flutter) — version 3.0.1, Dart >=3.8.1 requirement. **HIGH confidence.**
- [pub.dev: convex_flutter versions](https://pub.dev/packages/convex_flutter/versions) — confirmed 3.0.1 is latest (Feb 2026).
- [Convex Auth docs](https://docs.convex.dev/auth/convex-auth) — confirmed Flutter not supported by Convex Auth, only React/React Native. **HIGH confidence.**
- [Convex Custom JWT Provider](https://docs.convex.dev/auth/advanced/custom-jwt) — workaround for non-React clients. **MEDIUM confidence** (underdocumented for Flutter).
- [pub.dev: google_generative_ai](https://pub.dev/packages/google_generative_ai) — confirmed deprecated, version 0.4.7 is last. **HIGH confidence.**
- [Firebase: Migrate from google_generative_ai](https://firebase.google.com/docs/ai-logic/migrate-from-google-ai-client-sdks) — official migration guide to `firebase_ai`. **HIGH confidence.**
- [pub.dev: firebase_ai](https://pub.dev/packages/firebase_ai) — version 3.8.0, published Feb 2026. **HIGH confidence.**
- [pub.dev: firebase_messaging](https://pub.dev/packages/firebase_messaging) — version 16.1.1, Flutter Favorite. **HIGH confidence.**
- [pub.dev: google_sign_in](https://pub.dev/packages/google_sign_in) — version 7.2.0, v7 is current stable. **HIGH confidence.**
- [pub.dev: googleapis_auth](https://pub.dev/packages/googleapis_auth) — explicitly says "Do NOT use with Flutter." **HIGH confidence.**
- [pub.dev: extension_google_sign_in_as_googleapis_auth](https://pub.dev/packages/extension_google_sign_in_as_googleapis_auth) — version 3.0.0, official flutter.dev package. **HIGH confidence.**
- [pub.dev: googleapis](https://pub.dev/packages/googleapis) — version 16.0.0, official Google package. **HIGH confidence.**
- [pub.dev: flutter_riverpod](https://pub.dev/packages/flutter_riverpod) — version 3.2.1, published Feb 2026. **HIGH confidence.**
- [pub.dev: riverpod_generator](https://pub.dev/packages/riverpod_generator) — version 4.0.3, published Feb 2026. **HIGH confidence.**
- [pub.dev: go_router](https://pub.dev/packages/go_router) — version 17.1.0, maintained by flutter.dev. **HIGH confidence.**
- [pub.dev: freezed](https://pub.dev/packages/freezed) — version 3.2.5, Flutter Favorite, published Feb 2026. **HIGH confidence.**
- [pub.dev: json_serializable](https://pub.dev/packages/json_serializable) — version 6.13.0, published Feb 2026. **HIGH confidence.**
- [pub.dev: dio](https://pub.dev/packages/dio) — version 5.9.1, published Jan 2026. **HIGH confidence.**
- [pub.dev: speech_to_text](https://pub.dev/packages/speech_to_text) — version 7.3.0. **HIGH confidence.**
- [pub.dev: image_picker](https://pub.dev/packages/image_picker) — version 1.2.1. **HIGH confidence.**
- [pub.dev: flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — version 20.1.0, requires Flutter >=3.22. **HIGH confidence.**
- [pub.dev: flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — version 10.0.0, Dec 2025. **HIGH confidence.**
- [pub.dev: purchases_flutter](https://pub.dev/packages/purchases_flutter) — version 9.12.3, Feb 2026. **MEDIUM confidence** (RevenueCat pricing/cut not fully researched).
- [pub.dev: syncfusion_flutter_xlsio](https://pub.dev/packages/syncfusion_flutter_xlsio) — version 32.2.7, requires Syncfusion license. **LOW confidence** (licensing needs validation).
- [Flutter: What's New](https://docs.flutter.dev/release/whats-new) — confirmed Flutter 3.41.2 is current stable (Feb 11, 2026). **HIGH confidence.**
- [Convex Pricing](https://www.convex.dev/pricing) — free Starter plan (1M calls/month), no credit card. **MEDIUM confidence.**
- [Convex Auth: Google OAuth](https://labs.convex.dev/auth/config/oauth/google) — Google OAuth config steps for Convex Auth (web/React only). **MEDIUM confidence** for Flutter adaptation.
- [Firebase AI Logic docs](https://firebase.google.com/docs/ai-logic) — confirmed Gemini 2.5 Flash and 3.1 Flash model support. **HIGH confidence.**

---

*Stack research for: Intern Growth Vault — Flutter + Convex + Gemini + Google Calendar + GitHub*
*Researched: 2026-02-28*
