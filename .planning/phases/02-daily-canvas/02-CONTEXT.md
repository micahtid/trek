# Phase 2: Daily Canvas - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

A frictionless daily workspace where interns capture reflections via text and voice, then find them again through search. Covers: entry CRUD, voice transcription, full-text search with date filtering, and auto-timestamping. AI follow-up questioning, skill tagging, and photo capture are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Canvas workspace
- Card stream layout — each entry is a distinct card in a scrollable feed
- FAB (floating action button) opens a bottom sheet for composing new entries
- Bottom sheet is lightweight, slides up, and focuses on quick capture
- Canvas shows today's entries only — past days accessible through search or history

### Voice input
- Mic button lives inside the compose bottom sheet, next to the text field
- Voice and text share the same compose surface — unified input
- Transcription appears as editable text in the text field (draft-style, user can polish before saving)
- Voice entries display a subtle mic icon/badge on their card in the feed

### Entry display & management
- Cards show 2-3 line preview of entry text plus creation timestamp
- Tap a card to open full view with edit and delete actions inside
- Delete uses undo snackbar — immediate deletion with a few-second undo window
- Empty state shows a motivating prompt (illustration/icon + "What did you work on today?")

### Search
- Search icon in the app bar opens a full-screen search experience
- Results displayed in same card format as the daily feed (preview + timestamp, grouped by date)
- Supports full-text search plus optional date range filtering
- Search covers all entries across all days

### Claude's Discretion
- Voice recording visual feedback (waveform, pulsing icon, etc.)
- Empty search results state design
- Exact card spacing, typography, and shadow styling
- Loading states and error handling
- How the bottom sheet expands for longer entries

</decisions>

<specifics>
## Specific Ideas

No specific product references — open to standard Flutter/Material approaches. Key themes: frictionless capture (bottom sheet, not full navigation), scannable feed (preview cards, not walls of text), and clear input modes (voice and text together, not separate flows).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-daily-canvas*
*Context gathered: 2026-03-03*
