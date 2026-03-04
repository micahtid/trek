# Feature Research

**Domain:** Intern growth tracking / professional journaling / accomplishment vault
**Researched:** 2026-02-28
**Confidence:** MEDIUM (WebSearch + competitor site review; no official SDK docs applicable to feature landscape)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Rich text entry creation | Every journaling app has this; plain text alone feels stripped | LOW | Markdown or rich-text editor; headers, bold, italic at minimum |
| Full-text search across all entries | Users expect to find anything they wrote instantly; apps like Day One, Notion make this standard | LOW | Searchable by keyword, tag, and date; Convex supports this natively |
| Tag / label system | Expected in every productivity and journaling app; how users self-organize | LOW | Auto-tags (#SQL, #PublicSpeaking) are the differentiator; manual tags are table stakes |
| Cloud sync across devices | Every modern app syncs automatically; losing a journal entry is catastrophic | LOW | Convex handles real-time sync out of the box |
| Push notification reminders | Habit-building apps universally use reminders; without them users forget to journal | MEDIUM | Event-triggered notifications (post-meeting) vs generic reminders are distinct — generic is table stakes, event-triggered is a differentiator |
| Entry editing and deletion | Basic CRUD — already partially built; non-negotiable | LOW | Already exists in scaffold |
| Date/time metadata on entries | Every journaling app auto-stamps entries; users expect it | LOW | Auto-captured by device |
| Privacy and data security | Users expect their professional notes to be private | MEDIUM | Auth + per-user data isolation in Convex; encryption at rest |
| User authentication (sign in / sign up) | No app exists without auth | LOW | Google OAuth is the chosen method; already in scope |
| Data export | Users need to own their data permanently — especially career data | MEDIUM | CSV/Excel export is already in requirements; important trust signal |
| Reminders / habit nudges | Generic periodic reminders are expected by journaling app users | LOW | "Don't forget to log today" — table stakes version of the AI nudge |
| Entry history / timeline view | Users expect to scroll back through past entries chronologically | LOW | Calendar view or feed; standard in Day One, Journey |
| Offline entry creation (graceful degradation) | Not offline-first, but must not crash or lose data if connectivity drops briefly | MEDIUM | Convex's reactive model handles reconnection; brief local queuing needed |

---

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required by convention, but create genuine value and competitive separation.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Google Calendar event auto-detection | Eliminates blank canvas problem — meeting appears automatically, intern just reflects | HIGH | Requires Google Calendar OAuth scope, polling/webhook strategy; no competitor in this exact space does this |
| GitHub commit/PR auto-import | Gives developers automatic proof-of-work without copy-pasting; BragBook does GitHub import but not in a journaling UX | HIGH | GitHub REST API; commits, branch names, PR descriptions; filters to intern's own contributions |
| AI follow-up questioning (specificity drilling) | Core differentiator — AI won't accept "I learned a lot"; drills for percentages, concrete outcomes, names | HIGH | Gemini integration with multi-turn conversation; needs structured prompting and conversation state; no competitor does this for interns specifically |
| Five-pillar structured reflection framework | Imposes professional narrative structure (Key Learnings, Mistakes, Next Steps, Questions, What I Built Today) instead of free-form rambling | MEDIUM | Framework drives resume-ready entries vs diary entries; must be enforced but not feel like bureaucracy |
| Event-triggered push notifications (post-meeting) | "How did the 2pm design review go?" sent immediately after calendar event ends — not generic reminders | HIGH | Requires Calendar event completion detection + FCM/APNs push; highest-impact retention mechanic |
| Weekly AI formatting and vault archival | Raw daily notes auto-formatted into polished weekly summaries before being archived permanently | HIGH | Gemini batch processing; weekly workspace vs permanent vault distinction is unique |
| Permanent queryable vault | Career data that outlasts the internship; searchable years later | MEDIUM | Convex as long-term database; not just a journaling app but a professional record |
| Resume bullet point generation | Full-internship AI generation of STAR-format, quantified bullet points from vault data | HIGH | Requires full vault context; AI needs good examples; this is the end-state payoff that justifies daily logging habit |
| AI intentional gap detection | AI notices "you had 6 meetings today but only logged 2" and proactively asks about the gap | HIGH | Requires comparing Calendar events to logged entries; personalized, context-aware nudging |
| Voice-to-text entry | Captures reflections hands-free immediately after a meeting while memory is fresh | MEDIUM | Flutter speech-to-text plugins are mature; real-time transcription via device or Gemini |
| Photo capture (whiteboard, screenshots) | Captures visual artifacts of work that text cannot — whiteboard diagrams, error screenshots | MEDIUM | Image upload + Gemini vision for description extraction; stores visual context alongside reflection |
| Automated skill tagging with impact level | #SQL, #SystemDesign automatically extracted from entries and rated by impact — builds skill evidence automatically | HIGH | Gemini NLP extraction; skill taxonomy needs design; impact scoring is novel |
| AI companion for vault querying (subscription) | Natural language search: "Show me everything I learned about Kubernetes" — conversational vault access | HIGH | RAG over vault data; highest-value subscription feature; no general journaling app offers this for career data |
| Weekly accomplishment overview (motivating summary) | "Here's what you crushed this week" — emotional engagement, not just dry archival | MEDIUM | Gemini summary with tone guidance; combats imposter syndrome; retention mechanic |
| Internship-scoped resume generation | Generates bullets knowing this is a 10–12 week internship, not a full career — specific format guidance | HIGH | Requires intern-specific prompting and user-provided "good bullet" examples for reference |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem valuable on the surface but create scope, UX, or trust problems. Build these and you waste time or break the product.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Social / sharing feed | "LinkedIn for interns" sounds appealing; users want to see peers | Interns won't be honest in a journal that others can read — destroys the core value of honest reflection; trust collapse | Allow controlled export/share of specific polished bullets only (not raw journal) |
| Real-time collaboration / shared journals | Mentor + intern joint journaling sounds nice | Single-user journal is a private space; collaboration invites self-censorship and scope explosion | Let interns export formatted summaries to share with mentors |
| Email/password auth | Users without Google accounts exist | Adds auth complexity, security surface, password reset flows; target users (tech interns) all have Google accounts | Google OAuth only; stated in constraints |
| Company / HR admin dashboards | B2B feature requests will come | Changes the trust model entirely — interns won't journal honestly if their employer can read it; full product pivot | Keep B2C; never sell employer access to intern data |
| Mood / emotional tracking | Many journaling apps do this; users might ask for it | This is a professional tool, not a wellness app; mood tracking dilutes the career-growth focus and adds ML complexity | The five-pillar framework captures emotional context implicitly (Mistakes & Lessons) |
| Gamification / leaderboards | Streaks and points increase engagement metrics | Streak anxiety causes fake entries (one-word logs just to keep the streak); quality collapses | Milestone notifications that celebrate richness of entries, not frequency alone |
| Offline-first architecture | "What if I have no signal?" is a real concern | Full offline-first with sync is a major architectural investment; stated as out of scope; Convex requires connectivity | Graceful degradation: queue entry locally for seconds/minutes, sync on reconnect; do NOT build full conflict-resolution offline sync |
| Web application | Interns use their phones; web would reach more users | Doubles the platform surface; stated explicitly as deferred; mobile-first validates the concept | Defer web to a future milestone after mobile validates |
| Email notifications | Feels like a communication channel | Email is slow for time-sensitive "how did your meeting go?" moments; users tune out email | Push notifications only for time-sensitive nudges |
| Built-in note sharing / public profiles | "Share your learning journey" | Reduces honesty; interns perform for audience rather than reflect for growth | Resume bullet export is the shareable artifact, not raw journal entries |
| Manual time tracking / timesheets | "Track how long you spent on things" | Scope creep into timesheet territory; different problem, different app; adds burden vs reducing friction | Activity skeleton from Calendar already captures time implicitly through event duration |

---

## Feature Dependencies

```
[Google OAuth Login]
    └──requires──> [Google Calendar Integration]
                       └──requires──> [Event-Triggered Push Notifications]
                                          └──requires──> [AI Follow-up Questioning]

[Google OAuth Login]
    └──requires──> [Daily Canvas Dashboard]

[GitHub OAuth Connection]
    └──requires──> [Commit/PR Auto-Import]
                       └──enhances──> [Daily Canvas Dashboard]

[Daily Canvas Dashboard]
    └──requires──> [Manual Entry Creation]
    └──enhances──> [Five-Pillar Framework]

[Entry Creation (any method)]
    └──requires──> [Cloud Sync / Convex Backend]
    └──enables──> [Full-Text Search]
    └──enables──> [Automated Skill Tagging]

[Weekly Workspace]
    └──requires──> [Daily Canvas Dashboard]
    └──requires──> [Entry Creation]
    └──feeds──> [Weekly Vault Archival]

[Weekly Vault Archival]
    └──requires──> [AI Weekly Formatting]
    └──builds──> [Permanent Queryable Vault]

[Permanent Queryable Vault]
    └──requires──> [Weekly Vault Archival]
    └──enables──> [AI Vault Query Companion] (subscription)
    └──enables──> [Resume Bullet Point Generation] (subscription)

[Voice-to-Text Entry]
    └──enhances──> [Entry Creation]
    └──independent of──> [Photo Capture]

[Photo Capture]
    └──enhances──> [Entry Creation]
    └──independent of──> [Voice-to-Text Entry]

[AI Follow-up Questioning]
    └──requires──> [Entry Creation]
    └──requires──> [Gemini AI Integration]
    └──enhances──> [Automated Skill Tagging]

[Subscription Management]
    └──gates──> [AI Vault Query Companion]
    └──gates──> [Resume Bullet Point Generation]
    └──gates──> [AI Follow-up Questioning] (optional: could gate this too)
    └──does NOT gate──> [Permanent Vault Access] (data always free per design decision)

[AI Gap Detection]
    └──requires──> [Google Calendar Integration]
    └──requires──> [Entry Creation]
    └──requires──> [Gemini AI Integration]

[Resume Bullet Point Generation]
    └──requires──> [Permanent Queryable Vault] (needs full internship data)
    └──requires──> [Gemini AI Integration]
    └──requires──> [Subscription]
```

### Dependency Notes

- **Google OAuth gates Calendar**: Calendar integration requires the same Google OAuth session; this is one OAuth flow with additional Calendar scopes, not two separate auth systems.
- **Vault requires Weekly Archival**: Resume bullets only work well after weeks of accumulated, formatted vault data — this is why the UX loop has a "weekly transition" step.
- **Subscription gates AI, not data**: The design decision that data is always free means vault access/export/search must remain ungated; only AI-powered features (companion, resume generation, active questioning) are subscription-gated.
- **Push notifications are critical path**: If push notifications fail or get disabled by users, the core UX loop breaks. Event-triggered notifications are NOT optional — they are the trigger for the entire reflection workflow.
- **AI questioning conflicts with vague entries**: The AI follow-up system requires entries to start vague (the intern types something rough) and then be improved through dialogue. This means the entry creation flow must NOT force structure upfront — AI questioning adds structure iteratively.

---

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the core "AI that interviews you" concept.

- [ ] Google OAuth sign in / sign up — authentication gates everything
- [ ] Google Calendar integration (read events from previous day/today) — provides the activity skeleton
- [ ] Daily canvas dashboard with Calendar-sourced meeting skeleton — removes blank canvas problem
- [ ] Manual entry creation with five-pillar framework — structured reflection
- [ ] Voice-to-text input — frictionless capture immediately post-meeting (listed as v1 in PROJECT.md decisions)
- [ ] AI follow-up questioning (specificity drilling via Gemini) — the core differentiator; without this it's just another journal
- [ ] Event-triggered push notifications (post-meeting) — the trigger that starts the reflection habit
- [ ] Automated skill tagging — proves value accumulation to the intern
- [ ] Weekly workspace with AI vault archival — weekly summary validates the "your data compounds" promise
- [ ] Permanent queryable vault with full-text search — makes data feel valuable and retrievable
- [ ] Data export (CSV) — trust signal that intern owns their data
- [ ] Subscription management — gates AI features; needed before any monetization

### Add After Validation (v1.x)

Features to add once core loop is validated (interns are logging daily and finding entries useful).

- [ ] GitHub commit/PR integration — adds developer-specific proof of work; validate Calendar alone first
- [ ] Photo capture (whiteboard, screenshots) — enhances capture richness; add when voice is working well
- [ ] AI gap detection (calendar vs. logged entries comparison) — sophisticated nudging; requires Calendar integration to be stable first
- [ ] AI vault query companion — conversational vault search; needs substantial vault data to be useful (weeks of entries)
- [ ] Weekly accomplishment overview (motivating tone) — add when weekly archival is working; emotional engagement layer
- [ ] Timeline view for search results — UI polish on top of search

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Resume bullet point generation — needs a full internship's worth of data (10–12 weeks minimum); cannot validate until users complete an internship cycle
- [ ] Additional Google account attachment (multi-account Calendar) — edge case; validate single account first
- [ ] Export to Excel (in addition to CSV) — minor variation; deferred after core export is proven
- [ ] Web application — stated as explicitly out of scope for this milestone

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Google OAuth | HIGH | LOW | P1 |
| Google Calendar integration | HIGH | MEDIUM | P1 |
| Daily canvas dashboard | HIGH | MEDIUM | P1 |
| Manual entry creation (5-pillar) | HIGH | LOW | P1 |
| AI follow-up questioning (Gemini) | HIGH | HIGH | P1 |
| Event-triggered push notifications | HIGH | HIGH | P1 |
| Voice-to-text input | HIGH | MEDIUM | P1 |
| Weekly vault archival + AI formatting | HIGH | HIGH | P1 |
| Permanent queryable vault | HIGH | MEDIUM | P1 |
| Full-text search | HIGH | LOW | P1 |
| Automated skill tagging | MEDIUM | HIGH | P2 |
| Subscription management | HIGH | MEDIUM | P1 |
| Data export (CSV) | MEDIUM | LOW | P1 |
| GitHub commit/PR integration | HIGH | HIGH | P2 |
| Photo capture | MEDIUM | MEDIUM | P2 |
| AI gap detection | HIGH | HIGH | P2 |
| AI vault query companion | HIGH | HIGH | P2 |
| Weekly accomplishment overview | MEDIUM | MEDIUM | P2 |
| Timeline view for search | LOW | MEDIUM | P2 |
| Resume bullet point generation | HIGH | HIGH | P3 |
| Multi-account Google Calendar | LOW | MEDIUM | P3 |
| Excel export | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for launch (MVP)
- P2: Should have, add post-validation
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | BragBook | BragDoc | WorkSaga | Day One | Our Approach |
|---------|----------|---------|----------|---------|--------------|
| Calendar integration | None | None | None | None | Core — auto-populates daily skeleton from real meetings |
| GitHub integration | Yes (import only) | Yes (CLI, commit-only) | Yes (Jira, GitHub, Asana import) | IFTTT only | Yes — commits + PR descriptions, in-app, no CLI required |
| AI follow-up drilling | None | None | Review coach (different context) | None | Core differentiator — multi-turn specificity interviewing |
| Event-triggered push notifications | None (generic reminders only) | None | None | Customizable reminders | Core UX trigger — fires after each Calendar event ends |
| Structured reflection framework | Tags and collections | Categories | Career ladder mapping | Templates | Five-pillar framework enforced per entry |
| Permanent vault / searchable archive | Yes (BragBook entries) | Yes (local git history) | Yes (project-based) | Yes (journal entries) | Yes — with weekly archival transition and timeline view |
| Voice-to-text | None | None | None | Yes (premium) | Yes (v1) — critical for capture speed |
| Photo capture | None | None | None | Yes (premium) | Yes (v1) — whiteboard, screenshots |
| Resume bullet generation | Yes (performance review focused) | Yes (brag doc reports) | Yes (ATS-optimized CV) | No | Yes — intern-specific, full-vault context, end-of-internship |
| Skill tagging | Yes (auto-tag) | No | Yes (auto-tag) | No | Yes (auto-tag + impact level) |
| Subscription / free data | Free (25 entries) + $4.99/mo | Free (local) + $4.99/mo | Paid | Free + $34.99/yr | Data always free; AI features gated |
| Target user | Engineers, PMs, designers | Developers only | Engineers | General journalers | Tech interns specifically |
| Intern-specific UX loop | No | No | No | No | Yes — internship timeline, weekly cadence, end-of-internship output |

**Key gap in the market:** No competitor combines automatic activity capture (Calendar + GitHub) with AI-driven specificity questioning in a product designed specifically for the intern timeline (10–12 weeks → resume bullets). BragBook and BragDoc are closest but require manual logging and serve senior professionals, not interns learning to articulate their work.

---

## Sources

- BragBook features and pricing: https://bragbook.io/ (reviewed 2026-02-28, MEDIUM confidence)
- BragDoc features and pricing: https://www.bragdoc.ai/ (reviewed 2026-02-28, MEDIUM confidence)
- WorkSaga features: https://worksaga.app/ (reviewed 2026-02-28, MEDIUM confidence)
- LogYourWork features: https://logyourwork.com/brag-document (reviewed 2026-02-28, MEDIUM confidence)
- BragJournal features and pricing: https://bragjournal.ai/ (reviewed 2026-02-28, MEDIUM confidence)
- Day One features: https://dayoneapp.com/features/ (reviewed 2026-02-28, HIGH confidence — official docs)
- AI journaling app comparison: https://www.reflection.app/blog/ai-journaling-apps-compared (LOW confidence — single source)
- Best journaling apps 2025: https://www.rosebud.app/blog/best-journaling-app-2025-review (LOW confidence — marketing site)
- Push notification best practices and retention stats: https://www.businessofapps.com/marketplace/push-notifications/research/push-notifications-statistics/ (MEDIUM confidence)
- Journaling app market overview: https://www.betterup.com/blog/journaling-apps (LOW confidence)
- Resume bullet point generators: https://www.tealhq.com/tool/resume-bullet-point-generator (LOW confidence — product page)

---

*Feature research for: Intern Growth Vault — professional journaling + AI accomplishment tracking*
*Researched: 2026-02-28*
