# Feature: Wire Orphaned Nutrition Plan Screens into Trainee Navigation

## Priority
Critical — Phase 3 shipped complete plan screens but zero navigation paths reach them.

## User Story
As a trainee with an assigned nutrition template, I want to see my daily and weekly meal plans from the nutrition screen so that I know exactly what and how much to eat at each meal.

## Acceptance Criteria
- [ ] AC-1: When a trainee has an active template assignment (`state.hasTemplatePlan == true`), a "Meal Plan" card is visible on the nutrition screen
- [ ] AC-2: The card displays today's day type (via DayTypeBadge) and the template name
- [ ] AC-3: The card shows today's total target calories and P/C/F gram totals
- [ ] AC-4: Tapping the card navigates to `/nutrition/day-plan` with today's date
- [ ] AC-5: A "View Week" action navigates to `/nutrition/week-plan`
- [ ] AC-6: When no template is assigned, the card is NOT displayed
- [ ] AC-7: Card follows existing visual language (app_theme, dark/light mode)
- [ ] AC-8: Card is accessible: Semantics labels, 48dp tap target, screen reader support
- [ ] AC-9: DayPlanScreen back button returns to nutrition screen correctly
- [ ] AC-10: WeekPlanScreen day card tap navigates to DayPlanScreen with correct date

## Edge Cases
1. No template assigned — card hidden, no empty state clutter
2. Template assigned but day plan generation failed — card hidden, error shown on DayPlanScreen
3. Date changes on nutrition screen — card updates reactively for selected date
4. Data loading — card shows previous data, no flicker
5. Very long template name — ellipsis overflow, maxLines: 1
6. Trainee has presets but no template plan — independent systems, both can appear
7. Deep-link back from DayPlanScreen — nutrition screen date stays independent

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| No template assigned | No card (hidden) | hasTemplatePlan returns false |
| Day plan API 404 | No card (hidden) | dayPlan stays null |
| Day plan API 500 | No card for that day | Error caught, dayPlan null |
| Network offline | Stale data shown | Offline banner from existing widget |

## UX Requirements
- **Plan exists:** Card with DayTypeBadge, template name, calorie total, P/C/F mini macros, "View Week" button
- **No plan:** Card absent, zero visual footprint
- **Loading:** Not needed — overall screen spinner handles initial load
- **Tappable:** Full card tap for day plan, text button for week plan

## Technical Approach

### Files to modify:
1. `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` — Add meal plan card widget, insert conditionally in Column children

### Files to verify (no changes):
2. `mobile/lib/core/router/app_router.dart` — Routes exist at `/nutrition/day-plan` and `/nutrition/week-plan`
3. `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart` — `hasTemplatePlan`, `dayPlan`, `dayType`, `templateName` getters exist
4. `mobile/lib/features/nutrition/presentation/screens/day_plan_screen.dart` — Complete, no changes
5. `mobile/lib/features/nutrition/presentation/screens/week_plan_screen.dart` — Complete, no changes

### Reuse:
- `DayTypeBadge` widget from `widgets/day_type_badge.dart`
- `NutritionState` getters already defined
- go_router `context.push()` pattern

### No backend changes needed.

## Out of Scope
- Dedicated "Nutrition Plans" tab or bottom nav item
- Editing/overriding plans from trainee side
- Offline plan caching
- Plan card on trainee home screen
- Changes to DayPlanScreen or WeekPlanScreen UI
