# Phase 4: AI Follow-Up Questioning - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

After users create entries, Gemini actively drills them for specificity through a conversational follow-up flow, auto-tags entries with skills and impact level, and nudges toward the five professional reflection categories. Covers: AI follow-up questioning (AI-01), skill tagging and impact (AI-02), and category nudging (AI-03). Vault querying (AI-04), weekly archival, and resume generation are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Follow-up question flow
- Chat thread in entry detail view — after saving an entry, user is auto-navigated to entry detail where AI questions appear as a mini conversation below the entry text
- AI asks up to 3-4 follow-up questions max, but user can dismiss early at any point via explicit "I'm done" button or back navigation
- Follow-up answers are merged into the original entry body — AI consolidates the original text + answers into one clean, enriched reflection. The chat thread is ephemeral; the final entry reads as a polished paragraph
- Every new entry (text, voice, calendar reflection) triggers AI follow-up — consistent experience across all entry types
- If user skips or navigates away mid-drill, they can resume the AI conversation later from entry detail ("Continue AI drill-down" option)

### Skill tags & impact display
- Skill tags (#SQL, #PublicSpeaking, etc.) shown as colored chips below the entry text on feed cards — visible at a glance
- Tags generated after the AI drill-down completes (not during) — enriched entry body gives better tagging accuracy
- Users can accept or reject individual tags but cannot create new ones or rename — AI controls the vocabulary
- Impact level display: Claude's discretion on visual approach (based on M3 theme and existing card patterns)

### Category nudging
- AI's follow-up questions are crafted to naturally draw out category-relevant details (e.g., "What's your next step on this?" nudges toward Next Steps) — subtle prompting, not rigid forms
- Category assigned after drill-down based on enriched content — primary category displayed prominently, optional secondary categories shown smaller
- Category display placement on cards: Claude's discretion based on existing EntryCard layout
- Users can fully override AI-assigned categories — change primary, add/remove secondaries

### Trigger timing & scope
- AI follow-up fires on every new entry — text, voice, and calendar reflections all get drilled
- Client vs. server-side AI calls: Claude's discretion based on firebase_ai SDK patterns and existing Convex architecture
- Skip/exit: explicit "I'm done" button always visible in the chat thread, plus back navigation also ends the session gracefully
- Interrupted conversations are resumable — entry detail shows "Continue" option if drill-down was not completed

### Claude's Discretion
- Impact level visual design (dot, badge, stars, etc.)
- Category chip placement on entry cards
- Client-side vs. Convex server-side Gemini API calls
- Chat thread visual design (bubble style, spacing, animations)
- Loading states while waiting for Gemini responses
- Exact follow-up question phrasing and conversation flow
- How the entry body merge/consolidation works visually
- Error handling for Gemini API failures or rate limits

</decisions>

<specifics>
## Specific Ideas

- Phase 3 established a "casual coach" tone ("How did Sprint Planning go?") — follow-up questions should continue this same voice, not switch to a formal interviewer
- The compose sheet already uses "How did [event] go?" as a conversational opener — the AI drill-down extends this natural conversation
- Follow-up questions should steer toward specificity: percentages, counts, concrete outcomes, named tools/technologies — this is the core differentiator ("the AI won't accept vague entries")
- Entry merge should produce text that reads like the user wrote it themselves — not a Q&A transcript

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- **ComposeSheet** (`lib/features/today/presentation/compose_sheet.dart`): Bottom sheet with text + voice input, optional `calendarEventId` linking — entry creation flow to hook AI trigger into
- **EntryDetailScreen** (`lib/features/today/presentation/entry_detail_screen.dart`): Full entry view with edit/delete — extend with AI chat thread below entry text
- **EntryCard** (`lib/features/today/presentation/entry_card.dart`): surfaceContainerLow card with body preview, timestamp, mic/meeting badges — extend with skill chips and category labels
- **Entry model** (`lib/features/today/domain/entry.dart`): `id`, `userId`, `body`, `inputMethod`, `creationTime`, `calendarEventId` — needs new fields: `skillTags`, `impactLevel`, `primaryCategory`, `secondaryCategories`, `aiDrilldownStatus`
- **EntryRepository** (`lib/features/today/data/entry_repository.dart`): CRUD operations via ConvexHttpService — extend with AI metadata update methods

### Established Patterns
- **Riverpod providers**: `todayEntriesProvider`, `currentUserIdProvider` — add AI-related providers (drill-down state, pending questions)
- **Convex HTTP service**: Query/mutation pattern via `ConvexHttpService.instance` — use for AI metadata storage
- **firebase_ai ^3.8.0**: Confirmed Gemini package (not `google_generative_ai` which is deprecated)
- **Casual coach tone**: Established in Phase 3 notification copy — AI questions should match this voice

### Integration Points
- **Post-save hook**: After `ComposeSheet._saveEntry()` completes, navigate to EntryDetailScreen with AI drill-down active
- **Entry model expansion**: Add skill tags, impact, categories to Convex `entries` schema and Entry class
- **Convex backend** (`C:/Users/micah/OneDrive/Desktop/intern_vault/back_end/`): May need Convex actions for server-side Gemini calls
- **EntryCard**: Add chip row for skill tags below body text, before timestamp row

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-ai-follow-up-questioning*
*Context gathered: 2026-03-04*
