# Hacker Report: Full Trainer→Trainee Impersonation Token Swap (Pipeline 27)

## Date: 2026-02-20

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| — | — | — | — | — | No dead UI found. The previously dead "View as Trainee" button is now fully functional. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix | Status |
|---|----------|-----------------|-------|-----|--------|
| 1 | Minor | TrainerImpersonationBanner | Banner content could overflow on narrow screens (320px) — name + Read-Only badge + button in one row | Added `flex-wrap` and `gap-2` to allow content to wrap gracefully | FIXED |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| — | — | — | — | — | No logic bugs found |

## Verified Flows
1. **Start impersonation** — Button → Dialog → Confirm → Toast → Navigate. WORKS.
2. **End impersonation** — Banner button → API call → Restore tokens → Navigate. WORKS.
3. **Failed start** — API error → Toast error → Stay on page. WORKS.
4. **Failed end** — API error → Warning toast → Still restore + redirect. WORKS.
5. **No impersonation state** — Navigate to /trainee-view directly → Redirect to /dashboard. WORKS.
6. **Double-click prevention** — Start: `isPending` disables button. End: `isEnding` guard. WORKS.
7. **Middleware routing** — TRAINEE role cookie → Redirected away from trainer/admin paths. WORKS.

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | Medium | Trainee view | Add a "Back to Trainee Detail" link/button in addition to the banner End button | Gives trainers a second path to exit — the End button in the banner might be missed |
| 2 | Low | Weight card | Consider allowing trainer to toggle kg/lbs display | Different regions prefer different units |
| 3 | Low | Program card | Show which week of the program the trainee is currently in | Helps trainer understand progress context |

## Summary
- Dead UI elements found: 0 (previously dead button now fixed!)
- Visual bugs found: 1 (fixed)
- Logic bugs found: 0
- Improvements suggested: 3
- Items fixed by hacker: 1

## Chaos Score: 9/10
