# Roadmap: Intern Growth Vault

## Overview

Eight weeks of hard dependency-driven work: auth unlocks data, daily canvas proves the full stack, Calendar and push notifications trigger the reflection habit, AI questioning creates the core differentiator, GitHub adds developer proof-of-work, weekly archival compounds the data, and the vault query pays off everything that came before. Every phase delivers a coherent, testable capability that the next phase builds on.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation and Auth** - Working Flutter app with Google OAuth and Convex backend connected
- [ ] **Phase 2: Daily Canvas** - Full-stack entry creation with voice input, search, and skill tagging
- [ ] **Phase 3: Calendar Integration and Push Notifications** - Meeting skeleton auto-populated and event-triggered nudges firing
- [ ] **Phase 4: AI Follow-Up Questioning** - Gemini drilling entries for specificity after every event
- [ ] **Phase 5: GitHub Integration** - Commit and PR data auto-imported alongside Calendar events
- [ ] **Phase 6: Weekly Vault Archival** - Weekly AI summaries archived to permanent vault with accomplishment overview
- [ ] **Phase 7: Vault Query and Resume Generation** - Queryable career record, photo capture, and AI resume bullet generation

## Phase Details

### Phase 1: Foundation and Auth
**Goal**: Users can sign into the app with Google and have their identity securely connected to Convex
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04
**Success Criteria** (what must be TRUE):
  1. User can sign in with Google OAuth and land on the main app screen
  2. User reopens the app after closing it and remains signed in (session persists via Convex token refresh)
  3. User can sign out and is redirected to the login screen with all user-scoped data inaccessible
  4. User can grant Google Calendar read permission as a separate optional step after initial sign-in
  5. User can optionally connect a GitHub account from settings without disrupting their Google session
**Plans**: TBD

### Phase 2: Daily Canvas
**Goal**: Users have a frictionless daily workspace where they can capture reflections in any format and find them again
**Depends on**: Phase 1
**Requirements**: CANV-01, CANV-02, CANV-03, CANV-05, CANV-06, CANV-07
**Success Criteria** (what must be TRUE):
  1. User opens the app to a canvas screen where they can immediately start typing a reflection
  2. User can create, edit, and delete text entries; entries survive app restarts (persisted to Convex)
  3. User can speak into the app and see their words transcribed and saved as a text entry
  4. User can search across all entries and see matching results with the correct date/time stamp
  5. Every entry displays the date and time it was created without any user input
**Plans**: TBD

### Phase 3: Calendar Integration and Push Notifications
**Goal**: Users see their meetings auto-populated on the canvas and receive reflection prompts after events end
**Depends on**: Phase 1
**Requirements**: INTG-01, INTG-02, INTG-04
**Success Criteria** (what must be TRUE):
  1. User sees today's Google Calendar meetings listed on their daily canvas without manual entry
  2. User receives a push notification asking for a reflection within a few minutes after a Calendar event ends
  3. Tapping a push notification deep-links directly to the relevant entry on the daily canvas
  4. User opens the app after being away and sees prompts for any Calendar events that occurred since their last visit (pull-based catch-up)
**Plans**: TBD

### Phase 4: AI Follow-Up Questioning
**Goal**: After users create entries, Gemini actively questions them until entries are specific and quantified
**Depends on**: Phase 2, Phase 3
**Requirements**: AI-01, AI-02, AI-03
**Success Criteria** (what must be TRUE):
  1. After a user creates or speaks an entry, an AI follow-up question appears inline that asks for a specific detail (a percentage, a count, a concrete outcome)
  2. Entries are automatically tagged with skill labels (e.g., #SQL, #PublicSpeaking) and an impact level that the user can see
  3. The AI's follow-up questions steer entries toward the five professional reflection categories (Key Learnings, Mistakes and Lessons, Next Steps, Questions, What I Built Today) without forcing the user into a rigid form
**Plans**: TBD

### Phase 5: GitHub Integration
**Goal**: Users see their GitHub commits and PR descriptions auto-imported on the daily canvas alongside meetings
**Depends on**: Phase 1, Phase 2
**Requirements**: INTG-03
**Success Criteria** (what must be TRUE):
  1. User sees their GitHub commits from today listed on the daily canvas alongside Calendar events
  2. User sees PR descriptions imported and displayed as canvas items they can add reflections to
  3. GitHub data refreshes without hammering the API — repeated opens within 15 minutes show cached data
**Plans**: TBD

### Phase 6: Weekly Vault Archival
**Goal**: Users have a weekly workspace and their entries are automatically formatted, summarized, and archived to a permanent vault each week
**Depends on**: Phase 2, Phase 4
**Requirements**: VALT-01, VALT-02, VALT-03
**Success Criteria** (what must be TRUE):
  1. User can navigate to a weekly workspace view that shows all entries from the current week in one place
  2. At the end of the week, entries are AI-formatted and archived to the permanent vault without any user action required
  3. After archival, the user receives a motivating accomplishment overview that summarizes what they achieved that week
  4. Running archival twice for the same week does not create duplicate vault entries (idempotent)
**Plans**: TBD

### Phase 7: Vault Query and Resume Generation
**Goal**: Users can query their full career record in natural language, attach photos to entries, and generate resume bullet points from their complete vault
**Depends on**: Phase 6, Phase 4
**Requirements**: CANV-04, VALT-04, VALT-05, AI-04
**Success Criteria** (what must be TRUE):
  1. User can search their permanent vault with a natural language question (e.g., "show me everything I learned about databases") and get a curated answer from their own data
  2. User can attach a photo (whiteboard, screenshot) to an entry and the app converts it to a text description that becomes part of the entry
  3. User can request AI-generated resume bullet points from their full vault and receive polished, quantified bullet points ready to paste into a resume
  4. Vault query is subscription-gated — free users see the feature but are prompted to subscribe before results are returned
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Auth | 0/TBD | Not started | - |
| 2. Daily Canvas | 0/TBD | Not started | - |
| 3. Calendar Integration and Push Notifications | 0/TBD | Not started | - |
| 4. AI Follow-Up Questioning | 0/TBD | Not started | - |
| 5. GitHub Integration | 0/TBD | Not started | - |
| 6. Weekly Vault Archival | 0/TBD | Not started | - |
| 7. Vault Query and Resume Generation | 0/TBD | Not started | - |
