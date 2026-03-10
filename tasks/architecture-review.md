# Architecture Review: v6.5 Navigation Wiring

## Review Date

2026-03-10

## Files Reviewed

- `mobile/lib/features/home/presentation/widgets/v65_feature_cards.dart` (new)
- `mobile/lib/features/home/presentation/widgets/dashboard_content.dart` (modified)
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` (modified)
- `mobile/lib/features/exercises/presentation/screens/exercise_bank_screen.dart` (modified)
- `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` (modified)
- `mobile/lib/core/router/app_router.dart` (verified routes exist)

## Scope

Navigation-only change: adds v6.5 feature nav cards to the trainee dashboard, a "View Patterns" button to trainer's trainee detail screen, and minor fixes (URI encoding for query params).

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Card widgets live in the correct directory (`features/home/presentation/widgets/`)
- [x] No business logic in widgets -- pure navigation via `context.push()`
- [x] Consistent with existing patterns (StatelessWidgets with `const` constructors, theme-aware styling)
- [x] All routes verified as registered in `app_router.dart`

## Layering Assessment

**Correct decisions:**

1. `v65_feature_cards.dart` is placed in `features/home/presentation/widgets/` -- the right location since these cards are specific to the trainee home dashboard, not shared across features.
2. The `_FeatureNavCard` base class is file-private (underscore prefix), which correctly prevents other features from depending on this particular card layout while still allowing the public card classes (`TrainingPlansCard`, etc.) to be imported individually if needed.
3. The `trainee_detail_screen.dart` change adds a button inline rather than extracting a widget -- proportional for a single `IconButton`.

## Should `_FeatureNavCard` Live in `shared/widgets/`?

**No.** The existing `shared/widgets/` directory contains cross-cutting concerns: navigation shells, loading shimmers, health permission sheets, sync status badges. The `_FeatureNavCard` is a layout pattern specific to the v6.5 feature sections on the trainee home screen. If a similar card is needed elsewhere in the future, the pattern can be promoted to `shared/widgets/` at that point. Premature extraction would violate YAGNI.

## Scalability

| Concern                                                          | Assessment                                                                                                                                                                                                                          |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Adding more v6.5 feature cards                                   | Trivial -- add a new `StatelessWidget` wrapping `_FeatureNavCard` with route/icon/copy, then add it to `V65FeatureSection`                                                                                                          |
| Adding new card sections/groups                                  | Add another heading + card list block inside `V65FeatureSection`                                                                                                                                                                    |
| Cards needing dynamic visibility (e.g. role-based, feature-flag) | Would require passing context or a provider; current static approach is correct for the current scope                                                                                                                               |
| Route string drift                                               | Routes are hardcoded strings in both the cards and `app_router.dart` -- this is consistent with the rest of the codebase. Type-safe route constants would be better but that's a codebase-wide concern, not specific to this change |

The approach scales well for the expected trajectory (10-20 feature cards). No architectural concern.

## Issues Found and Fixed

### 1. FIXED -- `dashboard_content.dart` exceeded 150-line widget limit (Minor)

**File:** `dashboard_content.dart` (was 190 lines)

The inline v6.5 card sections (two section headers + six card widgets with padding) pushed the file to 190 lines, violating the project's mandatory 150-line widget file limit.

**Fix:** Extracted a `V65FeatureSection` composite widget in `v65_feature_cards.dart` that encapsulates both section headers and all card instances. `dashboard_content.dart` now references it as a single `const V65FeatureSection()` call. File reduced to 139 lines.

## Issues Documented (Not Fixed)

### 2. Hardcoded section title strings (Low)

**File:** `v65_feature_cards.dart` lines 196, 213

The section headers "Performance" and "AI Tools" are hardcoded English strings, not going through `context.l10n`. This is consistent with several other places in the codebase that use hardcoded strings (the existing dashboard section headers use `DashboardSectionHeader` with hardcoded strings too). Should be addressed in a future i18n sweep, not in this navigation-only change.

### 3. URI encoding inconsistency in trainee_detail_screen.dart (Low)

**File:** `trainee_detail_screen.dart` line 688

The AI chat button now correctly uses `Uri.encodeComponent(displayName)` (line 141), and the new patterns button does too (line 149). However, the calendar navigation at line 688 still passes `name=$displayName` without encoding. This is a pre-existing issue, not introduced by this change.

## Data Model Assessment

No data model changes. N/A.

## Technical Debt

| #   | Description                                       | Severity | Direction                         |
| --- | ------------------------------------------------- | -------- | --------------------------------- |
| 1   | Hardcoded English strings in section titles       | Low      | Unchanged (pre-existing pattern)  |
| 2   | Route strings duplicated between cards and router | Low      | Unchanged (codebase-wide pattern) |

No new tech debt introduced. The `V65FeatureSection` extraction slightly reduces debt by keeping `dashboard_content.dart` within the project's line limit.

## Architecture Score: 9/10

This is a clean, proportional navigation-wiring change. Correct file placement, correct layering, correct use of `const` constructors and theme-aware styling. Good accessibility (`Semantics` wrapper on `_FeatureNavCard`). All routes verified as registered. The only deduction is for hardcoded strings that skip l10n, which is a pre-existing pattern. One minor issue was found and fixed (150-line limit violation).

## Recommendation: APPROVE
