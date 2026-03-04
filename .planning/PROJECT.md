# Intern Growth Vault

## What This Is

A B2C mobile app for tech interns that captures daily activities — meetings, commits, reflections — and transforms them into a searchable professional knowledge base with AI-generated resume bullet points. Any tech intern can install it, connect their Google Calendar and GitHub, and start building a permanent record of their growth.

## Core Value

Every intern reflection becomes a future resume bullet point — the app actively interviews interns about their work until entries are specific and impactful enough to prove their value.

## Requirements

### Validated

- ✓ Flutter project scaffold with Material 3 theming — existing
- ✓ Basic note CRUD (create, read, update, delete) — existing

### Active

- [ ] Google OAuth authentication (sign up and sign in)
- [ ] Attach additional Google accounts for Calendar integration
- [ ] Optional GitHub account connection
- [ ] Google Calendar integration (display completed meetings/sessions)
- [ ] GitHub integration (display commits, branches, PR descriptions)
- [ ] Daily canvas dashboard with automated activity skeleton
- [ ] Manual entry creation alongside automated data (text input)
- [ ] Voice-to-text input for quick capture
- [ ] Photo upload input (whiteboard sketches, screenshots)
- [ ] Five-pillar categorization (Key Learnings, Mistakes & Lessons, Next Steps, Questions to Answers, What I Built Today)
- [ ] AI proactive nudging via push notifications after events
- [ ] AI follow-up questions that dig for specificity (percentages, concrete outcomes)
- [ ] AI intentional hinting (detecting gaps between activity and reflections)
- [ ] Automated skill tagging (#SQL, #PublicSpeaking) and impact level
- [ ] Weekly workspace for raw data and active editing
- [ ] Weekly vault transition with AI formatting and summary generation
- [ ] Weekly accomplishment overview (exciting, motivating summary)
- [ ] Long-term permanent vault (queryable database)
- [ ] Customizable database querying for vault history
- [ ] Timeline view for search results
- [ ] AI companion for querying vault data (subscription feature)
- [ ] Resume bullet point generation from full internship vault data
- [ ] Export to Excel and CSV formats
- [ ] Push notifications (proactive, event-driven)
- [ ] Subscription management (free database + paid AI features)

### Out of Scope

- Web application — mobile-first, web deferred to future milestone
- Native iOS/Android — Flutter handles cross-platform
- Real-time collaboration — single-user personal tool
- Company/admin dashboards — B2C, not B2B
- Email/password auth — Google OAuth only
- Offline-first architecture — online-connected experience

## Context

**Current state:** The repo contains a basic Flutter notes app (single-file, in-memory, no persistence). This serves as the project scaffold but will be completely rebuilt for the Intern Growth Vault.

**Target users:** Tech interns at any company who want to track their growth, capture daily accomplishments, and build evidence for future resume writing and interview preparation.

**Core UX loop:**
1. Intern finishes a meeting or pushes a commit
2. App detects event via Calendar/GitHub integration
3. Push notification arrives: "How did the ___ meeting go?"
4. Intern adds a reflection (text, voice, or photo)
5. AI nudges for more specificity: "You said you made it faster — by what percentage?"
6. AI continues until the entry is rich enough to be useful
7. End of week: AI formats, summarizes, and archives to permanent vault
8. End of internship: AI generates resume bullet points from the full vault

**Monetization:** Subscription model. The database and data are always free (interns own their data). AI features (nudging, querying, resume generation) require active subscription.

**Key differentiator:** The AI doesn't just record — it actively interviews. It won't accept vague entries. This transforms raw "I did stuff" into concrete, quantified accomplishments.

## Constraints

- **Tech stack**: Flutter (Dart) for mobile, Convex for backend/database, Gemini for AI
- **Auth**: Google OAuth as sole authentication method
- **Integrations**: Google Calendar API and GitHub API (both optional for users)
- **Notifications**: Push notifications are critical to the core experience — must work reliably
- **Data ownership**: Interns always have access to their data, even without subscription
- **Resume reference**: User will provide examples of "good" resume bullet points to guide AI generation

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over React Native | User preference, good Convex/Firebase ecosystem support | — Pending |
| Convex over Firebase/Supabase | Reactive backend, serverless functions, real-time sync | — Pending |
| Gemini over Claude/OpenAI | User preference for AI engine | — Pending |
| Google OAuth only | Target users are tech interns, all have Google accounts. Simplifies auth | — Pending |
| Subscription + free database | Interns own data permanently, AI features drive revenue | — Pending |
| Resume bullets at internship end | Needs full context of entire internship for best results | — Pending |
| Voice + photo in v1 | Multimodal input is core to frictionless capture, not a nice-to-have | — Pending |
| Both Calendar + GitHub in v1 | Activity skeleton needs both sources to be useful | — Pending |

---
*Last updated: 2026-02-27 after initialization*
