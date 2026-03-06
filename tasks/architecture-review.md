# Architecture Review: Wire Nutrition Template Assignment

## Review Date: 2026-03-05

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Consistent with existing patterns
- [x] No business logic in views

The feature follows the Screen -> Provider -> Repository -> ApiClient layering correctly:

- **Models** (`nutrition_template_models.dart`): Freezed data classes with proper JSON serialization. Located in `data/models/` as expected.
- **Repository** (`nutrition_template_repository.dart`): Handles all HTTP calls via `ApiClient.dio`. Returns typed models, not raw maps. Follows the project's `datatypes.md` rule.
- **Providers** (`nutrition_template_provider.dart`): Thin Riverpod wrappers over repository methods. Uses `FutureProvider`, `FutureProvider.family`, and `FutureProvider.autoDispose.family` appropriately.
- **Screens**: `TemplateAssignmentScreen` is a `ConsumerStatefulWidget` (correct for form state). `_NutritionTemplateSection` is a `ConsumerWidget` (correct for display-only).
- **Navigation**: Uses `go_router` with `context.push()` and `context.pop()`. Route registered in `app_router.dart` with path parameter parsing.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | No schema changes in this feature; uses existing backend models |
| Types correct | PASS | Freezed models match backend API contract. `@JsonKey` annotations align field names |
| No type mismatches | PASS | `parameters` and `dayTypeSchedule` correctly typed as `Map<String, dynamic>` for flexible JSON |
| Provider families keyed correctly | PASS | `traineeActiveAssignmentProvider` keyed by `int` traineeId |

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Provider memory | `dayPlanProvider` and `weekPlansProvider` were non-autoDispose `FutureProvider.family` keyed by date strings — unbounded cache growth as users browse dates | **FIXED**: Changed both to `FutureProvider.autoDispose.family` so entries are cleaned up when no longer watched |
| 2 | Template list fetch | `nutritionTemplatesProvider` fetches all templates without pagination | Acceptable for now — template count is bounded (tens, not thousands). Add pagination if template count grows significantly |
| 3 | Active assignment fetch | `getActiveAssignment` fetches all assignments then filters client-side for `isActive` | Minor — should add `?is_active=true` query param server-side. Acceptable while assignment count per trainee remains small |

## Technical Debt
| # | Description | Severity |
|---|-------------|----------|
| 1 | `_NutritionTemplateSection` is 192 lines, exceeding the 150-line widget rule. Should be extracted to its own file. However, the parent `trainee_detail_screen.dart` is 2967 lines — this is a pre-existing debt issue that requires a broader decomposition effort, not scoped to this feature. | Minor (pre-existing) |
| 2 | `TemplateAssignmentScreen` is 322 lines. The form could be split into sub-widgets for template selector, parameter fields, schedule config, and fat mode selector. | Minor |
| 3 | `_submit()` in `TemplateAssignmentScreen` calls repository directly via `ref.read(nutritionTemplateRepositoryProvider)` rather than through a dedicated mutation provider/notifier. This is consistent with existing patterns in the codebase (e.g., `trainee_list_screen.dart`, `invite_trainee_screen.dart`) but bypasses provider-level cache invalidation. The caller (`_NutritionTemplateSection`) compensates by calling `ref.invalidate()` after `context.push()` returns. | Minor (consistent with codebase) |
| 4 | `createdAt` is typed as `String?` rather than `DateTime?` across all models. Date parsing happens ad-hoc in UI (`.split('T').first`). A `DateTime` type with a custom `JsonConverter` would be cleaner. | Minor (pre-existing pattern) |

## Fixes Applied
1. Changed `dayPlanProvider` and `weekPlansProvider` to use `autoDispose` to prevent unbounded memory growth when users browse different dates.

## Architecture Score: 8/10
## Recommendation: APPROVE

The feature is well-structured and follows all established patterns in the codebase. The layering is correct, types are sound, and state management uses Riverpod properly. The autoDispose fix addresses the only concrete scalability issue. Remaining items are minor and either pre-existing or consistent with current conventions.
