# Code Review: Wire v6.5 Navigation

## Review Date

2026-03-10

## Files Reviewed

- `mobile/lib/features/home/presentation/widgets/v65_feature_cards.dart`
- `mobile/lib/features/home/presentation/widgets/dashboard_content.dart`
- `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart`
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart`
- `mobile/lib/features/exercises/presentation/screens/exercise_bank_screen.dart`
- `mobile/lib/core/router/app_router.dart` (reference — not changed)

## Critical Issues (must fix before merge)

_None found._

## Major Issues (should fix)

| #   | File:Line                               | Issue                                                                                                                                                                                                                                                                                                                                                                 | Suggested Fix                                                                                                                                                              |
| --- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `exercise_bank_screen.dart:423,879`     | `/lift-history/${exercise.id}` is missing the `?name=` query parameter. The router does `state.uri.queryParameters['name'] ?? 'Exercise'`, so the LiftHistoryScreen will show a generic "Exercise" title instead of the actual exercise name. Both the detail sheet (line 423) and quick-actions menu (line 879) have this bug.                                       | Change to `parentContext.push('/lift-history/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}')` in both locations.                                               |
| 2   | `exercise_bank_screen.dart:436,890`     | `/auto-tag/${exercise.id}` is missing the `?name=` query parameter. Same issue — AutoTagScreen will show "Exercise" instead of the real name. Both the detail sheet (line 436) and quick-actions menu (line 890) have this bug.                                                                                                                                       | Change to `parentContext.push('/auto-tag/${exercise.id}?name=${Uri.encodeComponent(exercise.name)}')` in both locations.                                                   |
| 3   | `trainee_detail_screen.dart:150-151`    | `/trainer/trainee-patterns/${trainee.id}` is missing the `?name=` query parameter. The router does `state.uri.queryParameters['name'] ?? 'Trainee'`, so the TraineePatternsScreen will show "Trainee" instead of the actual trainee name.                                                                                                                             | Add `?name=${Uri.encodeComponent(displayName)}` to the route. The `displayName` variable is already computed on line 131.                                                  |
| 4   | `trainer_dashboard_screen.dart:360-580` | The 4 analytics cards are ~220 lines of nearly identical boilerplate (GestureDetector > Container > Row > icon container + text column + chevron). This violates the project convention of max 150 lines per widget file (these are inline in the build method, making the overall file even longer). Any future styling change requires updating 4 identical blocks. | Extract a reusable `_AnalyticsCard` helper widget that takes icon, color, title, subtitle, and route. Reduces ~220 lines to ~30 lines of call sites + ~40 lines of helper. |

## Minor Issues (nice to fix)

| #   | File:Line                                         | Issue                                                                                                                                                                                                                                                                                                                                                                                                               | Suggested Fix                                                                                                                                                                                                                       |
| --- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `trainee_detail_screen.dart:140-141`              | Variables `name` and `displayName` are re-declared inside the `onPressed` callback for the AI chat button, shadowing the identical variables already computed on lines 130-131. Both compute the exact same values from the same `trainee` object. Dead code duplication.                                                                                                                                           | Remove lines 140-141 and use the outer `displayName` variable directly (it is in scope via the closure over `trainee`).                                                                                                             |
| 2   | `v65_feature_cards.dart:84,146,206,266`           | `LiftMaxesCard`, `WorkloadCard`, `VoiceMemosCard`, `VideoAnalysisCard` use hardcoded `Colors.orange`, `Colors.purple`, etc. for icon container backgrounds instead of theme-derived colors. The `TrainingPlansCard` correctly uses `theme.colorScheme.primaryContainer` — the other 5 cards deviate from this pattern. This will look inconsistent with custom trainer branding (a current priority per CLAUDE.md). | Use `theme.colorScheme` variants (secondaryContainer, tertiaryContainer, etc.) or at minimum be consistent — either all cards use theme colors or all use hardcoded colors.                                                         |
| 3   | `v65_feature_cards.dart` (entire file, 369 lines) | All 6 cards are structurally identical, differing only in icon, color, title, subtitle, and route. 6 copies of the same ~60-line widget.                                                                                                                                                                                                                                                                            | Extract a single `_V65FeatureCard` private widget parameterized by icon, iconColor, iconBackgroundColor, title, subtitle, and route. Each public card becomes a one-liner delegating to it. Cuts file from 369 lines to ~100 lines. |
| 4   | `trainer_dashboard_screen.dart:363,417,471,525`   | Uses `GestureDetector` for the analytics cards instead of `InkWell`. `GestureDetector` provides no visual tap feedback (no ripple/highlight), which is inconsistent with Material Design and with the home screen cards that use `InkWell`. Users will perceive these cards as less responsive.                                                                                                                     | Replace `GestureDetector` with `InkWell` and add `borderRadius: BorderRadius.circular(12)` to match the container shape.                                                                                                            |
| 5   | `dashboard_content.dart:113`                      | Spacing before v6.5 cards section is `SizedBox(height: 8)` while spacing between all other sections is consistently `SizedBox(height: 16)`. The v6.5 section appears cramped relative to the rest of the dashboard.                                                                                                                                                                                                 | Change to `SizedBox(height: 16)` for visual consistency. Consider adding a section header text (e.g., "Training Tools") above the cards, matching the pattern used by other sections.                                               |
| 6   | `v65_feature_cards.dart` (all 6 cards)            | No semantic labels on the `InkWell` widgets. Screen readers will announce the card content but won't indicate these are navigation targets.                                                                                                                                                                                                                                                                         | Add `Semantics(button: true, label: 'Navigate to Training Plans')` wrapper or set `InkWell`'s tooltip property for each card.                                                                                                       |
| 7   | `dashboard_content.dart:163`                      | Pre-existing: `debugPrint('Failed to parse workout date: $e')` — project convention says "No debug prints — remove all `print()` before committing." While `debugPrint` is stripped in release builds, flagging for consistency.                                                                                                                                                                                    | Remove or replace with proper logging.                                                                                                                                                                                              |

## Security Concerns

- **Route parameter injection:** All exercise/trainee IDs are `int` types. The router does `int.parse(...)` which would throw a `FormatException` on non-integer input, handled by go_router's error page. No injection risk.
- **URI encoding:** Tag history route (line 902) correctly uses `Uri.encodeComponent(exercise.name)` for the name query param. However, the lift-history and auto-tag routes omit the name entirely (Major issues #1-2), so there is no encoding concern there — just missing data.
- **Pre-existing concern (not this PR):** `trainee_detail_screen.dart:143` passes `trainee_name=$displayName` to the AI chat route **without** `Uri.encodeComponent`, which could break routing if the name contains `&`, `=`, or `#` characters.

## Performance Concerns

- **6 additional cards in SingleChildScrollView:** The dashboard uses `SingleChildScrollView` which builds all children eagerly (not lazily). Adding 6 cards is fine for now, but the dashboard is growing long. If more sections are added, consider migrating to `CustomScrollView` with `SliverList` for lazy building.
- **No unnecessary rebuilds:** All 6 new cards are `const`-constructed in `dashboard_content.dart`, which is correct and avoids unnecessary rebuilds.
- **Trainer dashboard cards:** Not `const`-constructable because they're inline widgets using `theme`. This is expected and not a concern.

## Quality Score: 7/10

All routes match the router definitions. Parameter types (int IDs) are correct. The code works and navigates to the right places. The UI pattern is consistent within each file. However, 4 missing `?name=` query params will cause degraded UX (generic titles instead of real names), there is significant code duplication in both new files, and the trainer dashboard cards lack tap feedback (GestureDetector vs InkWell). The major issues are straightforward to fix.

## Recommendation: REQUEST CHANGES

**Must fix before re-review:**

- Major #1, #2, #3: Add missing `?name=` query parameters (4 call sites in exercise bank, 1 in trainee detail)
- Major #4 is recommended but not blocking

**Nice to fix:**

- Minor #1-6 (especially #3 and #4 for maintainability and UX polish)
