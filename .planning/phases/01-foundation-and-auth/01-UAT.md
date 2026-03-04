---
status: testing
phase: 01-foundation-and-auth
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md]
started: 2026-03-03T06:30:00Z
updated: 2026-03-03T06:30:00Z
---

## Current Test

number: 1
name: App launches with bottom navigation
expected: |
  App opens and displays a bottom navigation bar with three tabs: Today, Vault, and Settings.
  The Today tab is selected by default. The navigation bar uses Material 3 style (NavigationBar, not legacy BottomNavigationBar).
awaiting: user response

## Tests

### 1. App launches with bottom navigation
expected: App opens and displays a bottom navigation bar with three tabs: Today, Vault, and Settings. Today tab is selected by default.
result: [pending]

### 2. Tab navigation works
expected: Tapping Vault tab shows vault screen. Tapping Settings tab shows settings screen. Tapping Today returns to today screen. No slide animations between tabs.
result: [pending]

### 3. Sora font and amber theme visible
expected: All text uses Sora font (not system default). Amber/gold accent color visible in AppBar, NavigationBar indicators, and interactive elements. Light/white background throughout.
result: [pending]

### 4. Sign-in screen appearance
expected: On first launch (or after sign-out), sign-in screen appears with: app name "Intern Growth Vault", a tagline, and a "Sign in with Google" button. No bottom navigation visible on this screen.
result: [pending]

### 5. Google sign-in flow
expected: Tapping "Sign in with Google" shows Google's sign-in sheet/dialog. After selecting a Google account, you land on the Today tab with bottom navigation.
result: [pending]

### 6. Session persists across restart
expected: Close the app completely (swipe away from recents). Reopen the app. You remain signed in and land on the Today tab — no sign-in screen shown.
result: [pending]

### 7. Profile displayed in Settings
expected: Navigate to Settings tab. Your Google profile info is displayed: profile picture (or initials), display name, and email address.
result: [pending]

### 8. Sign-out works
expected: In Settings, tap sign-out. A confirmation dialog appears. Confirm sign-out. You are redirected to the sign-in screen. Bottom navigation disappears.
result: [pending]

### 9. Google Calendar connection
expected: In Settings > Connections, "Google Calendar" shows as not connected. Tapping "Connect" prompts for Calendar permission (NOT a full re-sign-in). After granting, it shows "Connected".
result: [pending]

### 10. GitHub connection
expected: In Settings > Connections, "GitHub" shows as not connected. Tapping "Connect" opens a browser for GitHub authorization. After authorizing, you return to the app and it shows "Connected" with your GitHub username. You are still signed into Google (not disrupted).
result: [pending]

## Summary

total: 10
passed: 0
issues: 0
pending: 10
skipped: 0

## Gaps

[none yet]
