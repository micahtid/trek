# Phase 3: Calendar Integration and Push Notifications - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Users see their Google Calendar meetings auto-populated on the daily canvas and receive reflection prompts after events end. Covers: Calendar event sync and display, push notifications triggered by event completion, deep-linking from notifications, and pull-based catch-up for missed events. AI follow-up questioning (Phase 4), GitHub integration (Phase 5), and weekly archival (Phase 6) are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Meeting display on canvas
- Dedicated agenda section at the top of the daily canvas, manual entries feed below
- Each event card shows: time, title, and status indicator (upcoming, in progress, ended/needs reflection, reflected, skipped)
- Tapping an event card opens the existing compose bottom sheet pre-linked to that event
- Agenda section is collapsible — starts expanded, user can minimize to focus on entries

### Reflection flow
- Compose sheet shows event title at top with a guiding question as placeholder text (e.g., "How did Sprint Planning go?")
- One reflection per event — 1:1 mapping between calendar event and entry
- After reflecting, event card updates to show green checkmark + 1-line preview of the reflection text; tapping opens the linked entry in detail view
- Linked entry appears in both places: the entries feed below (with a meeting badge on the card) and accessible from the event card in the agenda

### Notification timing & tone
- Push notification fires 5 minutes after a calendar event ends
- Casual coach tone — friendly and encouraging (e.g., "Hey, how did Sprint Planning go? 💭")
- No frequency cap — every calendar event gets its own notification regardless of how many meetings in a day
- "Reflection reminders" toggle in Settings to disable push notifications while keeping calendar sync active
- Tapping a notification deep-links directly to the relevant event/entry on the daily canvas

### Missed events catch-up (INTG-04)
- On app open, check for un-reflected events since the user's last app open (not limited to today — catches weekend gaps)
- Missed events surface inline in the agenda section with an orange "Needs reflection" badge — no extra banners or overlays
- When missed events span multiple days, group by date with date-labeled section headers (consistent with search results pattern from Phase 2)
- Users can dismiss an event without reflecting — swipe or tap X changes status to "skipped"

### Claude's Discretion
- Exact notification copy variations (beyond the established casual coach tone)
- Loading states while calendar events sync
- Error handling for Calendar API failures or token expiry
- How the collapsible agenda animates (expand/collapse transition)
- Event card visual design details (colors, icons, spacing)
- How "skipped" events display differently from "needs reflection"

</decisions>

<specifics>
## Specific Ideas

- Notification tone should feel like a supportive mentor, not a task manager — "Hey, how did [meeting] go?" not "You have an unlogged meeting"
- The prompt question in the compose sheet ("How did [event] go?") sets up the AI follow-up questioning pattern in Phase 4 — keep it conversational
- Agenda section should feel like a natural part of the canvas, not a separate feature bolted on

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- **ComposeSheet** (`lib/features/today/presentation/compose_sheet.dart`): Bottom sheet for entry creation — extend with optional `calendarEventId` parameter to pre-link entries to events
- **EntryCard** (`lib/features/today/presentation/`): Card component with surfaceContainerLow fill — use as base pattern for event cards (with visual differentiation)
- **CalendarAuthSection** (`lib/features/settings/calendar_auth_section.dart`): Already handles `calendar.readonly` scope grant via `authorizeScopes()` — extend for token capture
- **ConvexHttpService** (`lib/core/convex/convex_service.dart`): HTTP wrapper for Convex API — ready to call new calendar sync functions
- **GoRouter** (`lib/core/router/app_router.dart`): Routes for `/today`, `/vault`, `/settings` — extend `/today` route with query params for notification deep linking
- **Date grouping pattern** (search results): Timer-based debounce and date-grouped section headers from Phase 2 search — reuse for multi-day missed events

### Established Patterns
- **Riverpod providers**: `authNotifierProvider`, `currentUserIdProvider`, `todayEntriesProvider` — extend with `calendarEventsProvider`, `pendingNudgesProvider`
- **Convex subscribe pattern**: Real-time updates via `ConvexClient.subscribe()` returning `SubscriptionHandle` — use for calendar event state changes
- **Entry model**: `Entry` class with `id`, `userId`, `body`, `inputMethod`, `creationTime` — add optional `calendarEventId` field
- **Secure storage**: `FlutterSecureStorage` used for GitHub token — available for Calendar access token storage if needed client-side
- **Delete + undo pattern**: Immediate action with snackbar undo — reuse for event dismiss/skip

### Integration Points
- **Convex backend** (`C:/Users/micah/OneDrive/Desktop/intern_vault_backend/`): Add `calendarEvents` table and sync functions
- **Google OAuth tokens**: Currently captures ID token only — Phase 3 must also capture OAuth access token for Calendar API calls
- **Settings screen**: Add "Reflection reminders" toggle alongside existing Calendar connection UI
- **TodayScreen**: Add collapsible agenda section above existing entries feed
- **AndroidManifest / iOS config**: Register for FCM push notifications (firebase_messaging not yet installed)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-calendar-integration-and-push-notifications*
*Context gathered: 2026-03-04*
