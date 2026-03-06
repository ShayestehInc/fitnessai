# Hacker Report: Nutrition Phase 3 (LBM Formula Engine)

## Date: 2026-03-05

## Dead Buttons & Non-Functional UI
| # | Severity | Screen | Issue | Status |
|---|----------|--------|-------|--------|
| 1 | Medium | WeekPlanScreen / DayPlanScreen | Routes registered but no nav entry points from nutrition home | Known — entry points planned for Phase 4 |

## Logic Bugs Fixed
| # | Severity | Issue | Status |
|---|----------|-------|--------|
| 1 | HIGH | Providers silently swallowed API errors, showing empty instead of error state | FIXED |
| 2 | HIGH | Repository returned raw Map<String, dynamic> violating datatypes rule | FIXED |
| 3 | HIGH | IDOR — trainer could access any trainee's plans via trainee_id | FIXED |
| 4 | HIGH | template_assignment_screen used old Map result pattern | FIXED |

## Product Improvements (Noted for Follow-up)
- Pull-to-refresh on day/week plan screens
- Show isOverridden status indicator
- Weekly totals/averages row

## Summary
- Dead UI elements found: 2 (orphaned routes — entry points in Phase 4)
- Visual bugs found: 3 (hardcoded colors — minor)
- Logic bugs found: 4 (all fixed)
- Improvements suggested: 5
- Chaos Score: 7/10
