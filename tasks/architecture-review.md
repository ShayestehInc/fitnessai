# Architecture Review: Video Workout Layout

## Architectural Alignment
- [x] Follows existing layered architecture -- Web components use TanStack Query + apiClient. Mobile widget takes callbacks from parent (active workout screen owns the state).
- [x] Models/schemas in correct locations -- `WorkoutLayoutConfig` is in `trainer/models.py`, appropriate since trainers configure layout for their trainees.
- [x] No business logic in routers/views -- Layout config is simple CRUD; no complex logic to misplace.
- [x] Consistent with existing patterns -- Web follows hooks + mutation pattern. Mobile follows StatefulWidget pattern used by other workout layouts.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | `WorkoutLayoutConfig` is a new table with OneToOneField to User. Adding `VIDEO` to `LayoutType.choices` is backward-compatible (new enum value, not rename). Default remains `CLASSIC`. |
| Migrations reversible | PASS | New model creation is trivially reversible (drop table). Adding a choice value requires no migration. |
| Indexes added for new queries | WARN | Explicit `models.Index(fields=['trainee'])` is redundant -- `OneToOneField` already creates a unique index on the FK column. Not harmful but unnecessary. |
| No N+1 query patterns | PASS | `WorkoutLayoutConfig` is a OneToOne lookup by trainee ID -- single query. Web fetches with dedicated query key. No nested iteration. |

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Mobile video loading | `VideoPlayerController.networkUrl` downloads full video on each exercise change. For 8-10 exercise workouts, this means sequential network fetches with no prefetching. | Prefetch the next exercise's video controller while current exercise is active. Dispose previous after transition. |
| 2 | Mobile TextEditingControllers | `_syncControllers` grows controller lists but never shrinks them. If sets are ever removed, stale controllers remain. | Add cleanup logic for removed sets, or document that sets are append-only. |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `video_workout_layout.dart` is 1128 lines. Project convention is max 150 lines per widget file. | Major | Extract into separate files: `_VideoArea`, `_LoggingCard`, `_SetRow`, `_RestOverlay`, `_TopOverlay`, `_VideoControls`, `_ExerciseInfoSheet`. |
| 2 | `debugPrint` calls at lines 195 and 201. Project rules: "No debug prints -- remove all `print()` before committing." | Minor | Remove both `debugPrint` calls or replace with proper logging. |
| 3 | `_muscleGroupColor` switch statement duplicates domain knowledge that likely exists elsewhere (theme or constants). | Minor | Extract to shared utility or theme extension. |
| 4 | Hardcoded colors (`_cardBg`, `_inputBg`, color literals) violate "Centralized theme" convention. | Minor | Define in `app_theme.dart` and reference via `Theme.of(context)`. |
| 5 | `exercise-detail-panel.tsx` uses raw `<select>` and `<textarea>` instead of shadcn UI components used elsewhere. | Minor | Replace with shadcn Select and Textarea for consistency. |

## StatefulWidget Justification
The mobile `VideoWorkoutLayout` uses `StatefulWidget` instead of Riverpod. This is acceptable: `VideoPlayerController` and `TextEditingController` are imperative Flutter objects requiring `dispose()` lifecycle management. The widget correctly delegates all workout state mutations to parent callbacks (`onSetCompleted`, `onExerciseChanged`, etc.), keeping business logic outside. The `WidgetsBindingObserver` mixin for app lifecycle (pause/resume video) further justifies StatefulWidget.

## Architecture Score: 8/10
## Recommendation: APPROVE

The data model is clean and backward-compatible. Web components follow established patterns well. The main concern is the mobile widget's size (1128 lines vs. 150-line convention), which should be refactored into smaller files. The redundant index and debug prints are trivial fixes. Overall, the architecture is sound.
