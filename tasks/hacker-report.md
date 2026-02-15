# Hacker Report: Pipeline 8 - Trainee Workout History + Home Screen Recent Workouts

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | HIGH | Home > Latest Videos > `_VideoCard` | Play button overlay | Tapping the play button or video thumbnail navigates to a video player / opens video URL | Nothing happens. Entire card has no `onTap`, `GestureDetector`, or `InkWell`. The play button circle looks tappable but is purely decorative dead UI. |
| 2 | MEDIUM | Home > Latest Videos > `_VideoCard` | Heart / like icon | Tapping toggles like state and calls an API | No tap handler on the `Icon` widget. `isLiked` and `likes` are display-only from hardcoded data. No like API exists. |
| 3 | MEDIUM | Home > Header | Notification bell `IconButton` | Opens a notification feed or navigates to notifications screen | Shows a placeholder `AlertDialog` with "Notifications are coming soon!" text. Misleading -- button looks fully functional but is a stub. No trainee notification API exists on the backend. |
| 4 | LOW | Home > Latest Videos | Video data | Real video data from API | `_getSampleVideos()` returns 3 hardcoded `VideoItem` objects with Unsplash placeholder URLs. No video API exists on the backend. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | HIGH | `WorkoutHistoryCard` stats row (`workout_history_widgets.dart`) | Three `StatChip` widgets in a `Row` overflow on narrow screens (e.g., iPhone SE at 320dp). `Row` has no wrapping -- causes RenderFlex overflow error in debug mode and clipped text in release. | **FIXED**: Changed `Row` to `Wrap` with `spacing: 16, runSpacing: 8` so chips flow to next line on narrow devices. |
| 2 | LOW | `WorkoutDetailScreen` header (`workout_detail_screen.dart`) | Right column with 3+ `HeaderStat` entries can get tight when exercise count is high (e.g., "12 exercises") or duration is long. Not a crash but text could clip near edge. | Mitigated by existing `Row` + `Expanded` on left column. Low priority. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | INFO | `WorkoutDetailData._extractExercises` fragility | If workout data only has `sessions` key with no backward-compat `exercises` key at top level | Exercises should be extracted from within sessions | Current implementation only reads `data['exercises']` and returns `[]` if not found. Backend always saves a flat `exercises` key for backward compat (verified in `survey_views.py` line 298), so this is not currently broken. However, the readiness survey and post-workout survey extractors handle the sessions fallback correctly while exercises do not -- an inconsistency that could cause issues if the backward-compat layer is ever removed. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | HIGH | Workout Detail Header | Display total volume (`formattedVolume`) in the header stats. The data is fetched from the API (`totalVolumeLbs`) and the model has a `formattedVolume` getter, but it was never displayed anywhere. Volume is the #1 metric for progressive overload tracking -- "I lifted 12,450 lbs last session." | **FIXED**: Added `HeaderStat` with `Icons.monitor_weight_outlined` to the detail header when `totalVolumeLbs > 0`. |
| 2 | HIGH | All 4 new files | Zero `Semantics` widgets in `workout_history_screen.dart`, `workout_history_widgets.dart`, `workout_detail_screen.dart`, and `workout_detail_widgets.dart`. Screen readers cannot provide meaningful context for workout cards, exercise cards, survey badges, or error/empty states. | **FIXED**: Added `Semantics` to `WorkoutHistoryCard` (button with full descriptive label), `ExerciseCard` (name + set count), `SurveyBadge` (label + score), `HeaderStat` (value label). Added `Semantics(liveRegion: true)` to empty and error states. Used `ExcludeSemantics` on `StatChip` children to prevent duplicate announcements. |
| 3 | MEDIUM | Workout Detail | Add a "Start Similar Workout" button at the bottom of the detail view. Users review past workouts specifically to replicate or improve upon them. Currently they navigate back, go to programs, find the same workout, and start manually. | Not implemented -- requires mapping from historical workout name back to a program day, which involves non-trivial logic. |
| 4 | MEDIUM | Home > Recent Workouts | The `_RecentWorkoutCard` could show more stats per card -- duration and/or total volume alongside exercise count. Currently only shows date, name, and "X exercises". | Not implemented -- would require layout adjustment. Low effort but needs design decision on information density. |
| 5 | MEDIUM | Workout History | Missing search/filter capability. A user with 100+ logged workouts can only infinite-scroll. No way to filter by workout name, date range, or exercise name. | Would require backend query param support (`?workout_name=Push`, `?date_after=2026-01-01`) and a filter UI. Not trivial but high value for power users. |
| 6 | LOW | Workout History | Consider adding date group headers ("This Week", "Last Week", "February 2026") to break up the flat list visually. Currently all cards are at the same level with only inline date labels. | Would significantly improve scannability for users with many workouts. |
| 7 | LOW | Video Section | Either wire up video cards with actual tap navigation and like functionality, or remove the section entirely. Half-implemented UI with non-functional play buttons and like icons erodes user trust. | Requires a video content API and player integration. Better to conditionally hide the section until the backend supports it: `if (state.latestVideos.isNotEmpty && hasVideoApi)`. |

## Summary
- Dead UI elements found: 4
- Visual bugs found: 2
- Logic bugs found: 0 active (1 fragility noted)
- Improvements suggested: 7
- Items fixed by hacker: 4

## Items Fixed by Hacker

### Fix 1: Stats row overflow in WorkoutHistoryCard
**File:** `mobile/lib/features/workout_log/presentation/screens/workout_history_widgets.dart`
**Issue:** Three `StatChip` widgets in a `Row` cause RenderFlex overflow on narrow screens.
**Fix:** Changed `Row` to `Wrap(spacing: 16, runSpacing: 8)`. Chips now gracefully wrap to the next line.

### Fix 2: Accessibility -- Semantics across all 4 new files
**Files:**
- `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart` -- empty state and error state get `Semantics(liveRegion: true)`
- `mobile/lib/features/workout_log/presentation/screens/workout_history_widgets.dart` -- `WorkoutHistoryCard` gets descriptive `Semantics(button: true, label: ...)`, `StatChip` wrapped in `ExcludeSemantics` to avoid redundancy
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart` -- error state gets `Semantics(liveRegion: true, label: ...)`
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_widgets.dart` -- `ExerciseCard` gets `Semantics(label: ...)`, `SurveyBadge` gets `Semantics(label: ...)`, `HeaderStat` gets `Semantics(label: ...)` with `ExcludeSemantics` on children

### Fix 3: Total volume display in workout detail header
**File:** `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`
**Issue:** `totalVolumeLbs` fetched from API and stored in model but never displayed.
**Fix:** Added conditional `HeaderStat(icon: Icons.monitor_weight_outlined, value: workout.formattedVolume)` when `totalVolumeLbs > 0`.

### Fix 4: Pagination error retry (applied by linter)
**File:** `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart`
**Issue:** If `loadMore()` fails during infinite scroll, the footer showed nothing useful.
**Fix:** Added inline error text with retry `TextButton.icon` in the list footer when `state.error != null && state.workouts.isNotEmpty`.

## Chaos Score: 7/10

### Rationale
The core workout history feature is well-built and works correctly end-to-end. Data flows cleanly from backend through API to model to UI. Pagination, pull-to-refresh, error states, empty states, and shimmer loading are all properly implemented. The new `WorkoutDetailData` model centralizes JSON extraction logic nicely.

**Good:**
- End-to-end data flow works: backend query -> serializer -> API -> repository -> provider -> UI
- Backend correctly defers `nutrition_data` to avoid fetching unnecessary blobs
- Route guard on `/workout-detail` redirects to history if `extra` is wrong type
- Shimmer loading in detail screen uses real header data (summary) with placeholder cards
- Pull-to-refresh properly resets state before reloading

**Concerns:**
- 4 dead UI elements in the home screen (video section, notification bell) that predate this feature but appear alongside the new Recent Workouts section
- Zero accessibility before this fix pass -- all 4 new files had no `Semantics` widgets
- `WorkoutRepository` returns `Map<String, dynamic>` everywhere, violating the project's data type rules ("never return dict")
- `_extractExercises` doesn't handle the sessions fallback, unlike sibling extractors

**Risk Assessment:**
- **Low Risk**: Feature works correctly. No data loss, no crashes, no security issues.
- **Medium Risk**: Dead video UI alongside real workout data creates a jarring UX contrast.
- **Low Risk**: Accessibility issues now addressed with this fix pass.
