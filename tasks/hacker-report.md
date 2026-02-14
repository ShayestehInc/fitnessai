# Hacker Report: Trainer-Selectable Workout Layouts

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| — | — | — | — | No dead buttons found | All buttons functional |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | _LayoutOption | Border width 1→2px shift on selection | **FIXED:** Compensated padding |
| 2 | Low | MinimalWorkoutLayout | Badge 24x24 vs Classic 28x28 | **FIXED:** Standardized to 28x28 |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | High | Trainer layout picker | Open trainee → layout section → API returns error | Error shown | **FIXED:** Was silently falling back to classic, now shows error + retry |
| 2 | Medium | Trainee workout | Trainer changes layout, trainee starts new workout | New layout | Stale cache — layout fetched once at initState (acceptable: per AC, takes effect next workout) |
| 3 | Medium | Type cast safety | API returns unexpected data format | Graceful handling | **FIXED:** Added `is Map<String, dynamic>` type guard |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Trainer UI | Add layout preview/demo | Trainer is "blind" when choosing layouts |
| 2 | Medium | Active Workout | Add retry for failed layout fetch on trainee side | Currently falls back silently to classic |
| 3 | Low | Trainer UI | Bulk "assign layout to all trainees" | Saves time for trainers with many clients |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 2 (both fixed)
- Logic bugs found: 3 (2 fixed, 1 acceptable per AC)
- Improvements suggested: 3
- Items fixed by hacker: 4

## Chaos Score: 7.5/10
