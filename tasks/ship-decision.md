# Ship Decision: Nutrition Phase 4 — Wire Orphaned Plan Screens

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 9/10

## Summary
Small, focused change that activates Phase 3's investment by adding a meal plan card to the nutrition screen. All 10 acceptance criteria pass. Zero backend changes. Clean analyzer output.

## Remaining Concerns
None — this is a minimal wiring change with no risk.

## What Was Built
- Meal plan card on nutrition screen showing day type badge, template name, calorie target, and P/C/F macros
- Card tap navigates to DayPlanScreen, "View Week" button navigates to WeekPlanScreen
- Card conditionally rendered only when trainee has an active template assignment
- Fixed Future.wait type safety in nutrition provider for typed getDayPlan return
- Removed unused import in template_assignment_screen
