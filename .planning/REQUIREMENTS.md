# Requirements: Intern Growth Vault

**Defined:** 2026-03-01
**Core Value:** Every intern reflection becomes a future resume bullet point — the app actively interviews interns about their work until entries are specific and impactful enough to prove their value.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication

- [x] **AUTH-01**: User can sign up and sign in with Google OAuth
- [x] **AUTH-02**: User session persists across app restarts (Convex auth token refresh)
- [x] **AUTH-03**: User can optionally grant Google Calendar read permission (incremental scope)
- [x] **AUTH-04**: User can optionally connect a GitHub account for commit tracking

### Daily Canvas

- [ ] **CANV-01**: User opens to a frictionless input surface for capturing daily reflections
- [ ] **CANV-02**: User can create, read, update, and delete text entries
- [ ] **CANV-03**: User can input via voice, which is transcribed and converted to text
- [ ] **CANV-04**: User can attach photos, which are processed and described as text
- [ ] **CANV-05**: All input modes (text, voice, photo) converge into clean, formatted text entries
- [ ] **CANV-06**: User can search across all entries via full-text search
- [ ] **CANV-07**: Each entry is auto-stamped with date and time metadata

### Integrations

- [ ] **INTG-01**: User sees Google Calendar meetings auto-populated on their daily canvas
- [ ] **INTG-02**: User receives push notification after a Calendar event ends asking for reflection
- [ ] **INTG-03**: User sees GitHub commits and PR descriptions on their daily canvas
- [ ] **INTG-04**: App checks for missed Calendar events on open and surfaces reflection prompts (pull-based catch-up)

### AI Features

- [ ] **AI-01**: AI provides subtle, real-time inline follow-up suggestions while user types or speaks (specificity drilling)
- [ ] **AI-02**: AI automatically tags entries with skills (#SQL, #PublicSpeaking) and impact level
- [ ] **AI-03**: AI nudges entries toward professional reflection categories (Key Learnings, Mistakes & Lessons, Next Steps, Questions, What I Built) without forcing rigid structure
- [ ] **AI-04**: User can query their vault data via basic natural language AI companion

### Vault & Data

- [ ] **VALT-01**: User has a weekly workspace view showing current week's active entries
- [ ] **VALT-02**: Weekly entries are AI-formatted, summarized, and archived to permanent vault automatically
- [ ] **VALT-03**: User receives a motivating weekly accomplishment overview after archival
- [ ] **VALT-04**: User can query their permanent vault (searchable long-term database)
- [ ] **VALT-05**: AI generates resume bullet points from full vault data at end of internship

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Monetization

- **SUBS-01**: Subscription management via RevenueCat (free database + paid AI features)
- **SUBS-02**: Restore Purchases button and subscription terms for App Store compliance

### Data Export

- **EXPRT-01**: User can export vault data to CSV format
- **EXPRT-02**: User can export vault data to Excel format

### Enhanced AI

- **AI-05**: AI detects gaps between Calendar events and logged entries ("you had 6 meetings but only logged 2")
- **AI-06**: Comprehensive AI vault query companion (desktop-level depth)

### UI Enhancements

- **UI-01**: Timeline view for vault search results
- **UI-02**: Customizable database querying interface

### Integrations

- **INTG-05**: Multi-account Google Calendar support (attach additional Google accounts)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Social / sharing feed | Destroys honest reflection — interns won't be candid if others can read |
| Company / HR admin dashboards | Changes trust model — interns won't journal honestly if employer has access |
| Email / password auth | All tech interns have Google accounts; simplifies auth surface |
| Gamification / streaks | Streak anxiety creates low-quality one-word entries to maintain streak |
| Mood / emotional tracking | Dilutes career-growth focus; five-pillar framework captures this implicitly |
| Offline-first architecture | Convex requires connectivity; graceful degradation handles brief drops |
| Real-time collaboration | Single-user private journal; shared access invites self-censorship |
| Web application | Mobile-first for v1; web deferred to future milestone |
| Manual time tracking | Scope creep into timesheet territory; Calendar captures time implicitly |
| Email notifications | Push is faster and more relevant for time-sensitive post-meeting nudges |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Complete |
| AUTH-02 | Phase 1 | Complete |
| AUTH-03 | Phase 1 | Complete |
| AUTH-04 | Phase 1 | Complete |
| CANV-01 | Phase 2 | Pending |
| CANV-02 | Phase 2 | Pending |
| CANV-03 | Phase 2 | Pending |
| CANV-04 | Phase 7 | Pending |
| CANV-05 | Phase 2 | Pending |
| CANV-06 | Phase 2 | Pending |
| CANV-07 | Phase 2 | Pending |
| INTG-01 | Phase 3 | Pending |
| INTG-02 | Phase 3 | Pending |
| INTG-03 | Phase 5 | Pending |
| INTG-04 | Phase 3 | Pending |
| AI-01 | Phase 4 | Pending |
| AI-02 | Phase 4 | Pending |
| AI-03 | Phase 4 | Pending |
| AI-04 | Phase 7 | Pending |
| VALT-01 | Phase 6 | Pending |
| VALT-02 | Phase 6 | Pending |
| VALT-03 | Phase 6 | Pending |
| VALT-04 | Phase 7 | Pending |
| VALT-05 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0

---
*Requirements defined: 2026-03-01*
*Last updated: 2026-03-01 after roadmap creation*
