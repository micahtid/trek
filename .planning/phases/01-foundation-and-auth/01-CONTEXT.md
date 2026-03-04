# Phase 1: Foundation and Auth - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Working Flutter app with Google OAuth sign-in connected to Convex backend. Users can sign in, stay signed in across restarts, sign out, and optionally connect Google Calendar and GitHub from settings. This phase establishes the app shell, navigation, theming, and auth infrastructure that every subsequent phase builds on.

</domain>

<decisions>
## Implementation Decisions

### Sign-in experience
- Minimal + bold: logo, tagline, single "Sign in with Google" button
- No onboarding screens, no value pitch — confident and clean
- Tagline: Claude's discretion (something fitting for the "growth vault" brand)

### Visual design & branding
- Light + clean aesthetic: white/light gray backgrounds, modern feel
- Primary font: Sora (Google Font) — use throughout the app
- Primary accent color: amber/gold — ties to the "vault" concept
- Research modern, clean, aesthetic mobile design practices for implementation guidance

### Onboarding flow
- Straight to canvas after first Google sign-in — no setup wizard, no guided tour
- User lands on the main daily canvas screen immediately after auth

### Integration linking (Calendar & GitHub)
- Both connections live in Settings only — not prompted during onboarding or first use
- User discovers Calendar and GitHub connection when they're ready
- Optional — the app works without either integration

### App shell & navigation
- Bottom navigation tabs: Today / Vault / Settings (standard mobile pattern)
- Today tab = daily canvas (default landing screen)
- Vault tab = permanent vault / search
- Settings tab = profile, Calendar connection, GitHub connection, account management

### Claude's Discretion
- Specific tagline copy for sign-in screen
- Spacing, icon choices, and layout details
- Loading states and transitions
- Error state handling (token expiry, network issues)
- Exact bottom nav icon choices and tab naming
- Modern aesthetic research to inform design system decisions

</decisions>

<specifics>
## Specific Ideas

- Font: Sora (must use this, not system font)
- Amber/gold accent on light backgrounds — "vault" feeling without being dark/heavy
- The sign-in screen should feel confident — one button, no clutter
- Research modern clean mobile design patterns for aesthetic guidance

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-and-auth*
*Context gathered: 2026-03-01*
