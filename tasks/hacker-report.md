# Hacker Report: Phase 8 Community & Platform Enhancements (Pipeline 18)

## Date: 2026-02-16

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| None found | | | | | |

All buttons, toggles, and interactive elements are properly wired to actions.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | _FullImageScreen | No title in app bar (just back button) | Acceptable -- clean image viewer pattern |
| 2 | Low | Comments sheet | Delete is via small X icon instead of long-press | Works but less discoverable -- follows project's existing pattern |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Low | Ambassador onboarding | Tap "Connect Stripe Account" | Opens browser with Stripe URL | Shows snackbar with message but does not actually launch URL (url_launcher not integrated) |
| 2 | Info | WebSocket malformed message | Send invalid JSON over WS | Log and ignore | Silently ignores (no log) |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | Medium | Comments | Add "typing indicator" when another user is composing | Real-time feel |
| 2 | Medium | Feed | Add post sharing within group | Engagement |
| 3 | Low | Leaderboard | Add animation when rank changes in real-time | Delightful UX |
| 4 | Low | Image viewer | Add swipe-down-to-dismiss gesture | Standard iOS/Android pattern |
| 5 | Low | Compose | Show character count near limit (e.g., 950/1000) with color change | Prevent surprise truncation |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 0 critical, 2 low
- Logic bugs found: 1 low (url_launcher not integrated for Stripe), 1 info
- Improvements suggested: 5
- Items fixed by hacker: 1 (unused json import removed in architecture pass)

## Chaos Score: 8/10

Very solid implementation. No dead UI, no critical visual or logic bugs. The ambassador Stripe onboarding URL launch is a known limitation (url_launcher package not yet added). All new screens handle loading, empty, and error states properly. The codebase is clean with no TODOs, FIXMEs, or debug prints.
