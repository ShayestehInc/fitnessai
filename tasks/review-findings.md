# Code Review: Trainee Dashboard Redesign — Round 1

## Review Date
2026-03-08

## Files Reviewed
- `mobile/lib/features/home/presentation/screens/home_screen.dart` (233 lines)
- `mobile/lib/features/home/presentation/constants/dashboard_colors.dart` (25 lines)
- `mobile/lib/features/home/presentation/widgets/dashboard_header.dart` (161 lines)
- `mobile/lib/features/home/presentation/widgets/week_calendar_strip.dart` (118 lines)
- `mobile/lib/features/home/presentation/widgets/todays_workouts_section.dart` (191 lines)
- `mobile/lib/features/home/presentation/widgets/workout_card.dart` (178 lines)
- `mobile/lib/features/home/presentation/widgets/activity_rings_card.dart` (184 lines)
- `mobile/lib/features/home/presentation/widgets/activity_ring_painter.dart` (75 lines)
- `mobile/lib/features/home/presentation/widgets/health_metrics_row.dart` (193 lines)
- `mobile/lib/features/home/presentation/widgets/weight_log_card.dart` (147 lines)
- `mobile/lib/features/home/presentation/widgets/leaderboard_teaser_card.dart` (40 lines)
- `mobile/lib/features/home/presentation/widgets/dashboard_shimmer.dart` (129 lines)
- `mobile/lib/features/home/presentation/widgets/dashboard_error_banner.dart` (46 lines)
- `mobile/lib/features/home/presentation/widgets/dashboard_section_header.dart` (55 lines)
- `mobile/lib/features/home/presentation/providers/home_provider.dart` (514 lines)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `dashboard_shimmer.dart:33` | **Shimmer has no sweep effect.** The `_shimmerColor` getter computes a single uniform color based on `_controller.value`, so the ENTIRE skeleton pulses in unison rather than having a gradient sweep moving across. The ticket spec says "lighter zinc700 sweep" — a proper shimmer animates a highlight gradient left-to-right. Currently it looks like a dull global fade-in/fade-out. | Replace the uniform color approach with a `ShaderMask` using a `LinearGradient` whose `stops` are offset by `_controller.value`, giving a left-to-right shimmer sweep across all skeleton shapes. |
| C2 | `todays_workouts_section.dart:163` | **Silent `catch (_)` swallows all schedule parsing errors.** The project's error handling rule (`.claude/rules/error-handling.md`) says "NO exception silencing!" — errors during schedule parsing (malformed JSON, unexpected types) are silently discarded. If a trainer sets up a program with an unexpected format, the trainee sees zero workouts with no diagnostics. | At minimum, log with `debugPrint` inside `assert(() { ... return true; }())` (matching the pattern in `home_provider.dart:341-344`). Better: catch specific types (`FormatException`, `TypeError`) and rethrow truly unexpected errors. |
| C3 | `home_screen.dart:64-69` | **Pull-to-refresh debounce not implemented (ticket edge case #10).** The ticket explicitly requires: "if `isLoading` is already true, the refresh callback should not trigger a duplicate load." The `_onRefresh` method has no guard — pulling to refresh while a load is in flight fires a second `loadDashboardData()`. | Add at the top of `_onRefresh`: `final current = ref.read(homeStateProvider); if (current.isLoading) return;` |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `todays_workouts_section.dart:155-158` | **Difficulty is always hardcoded to `'Intermediate'`.** AC-4 specifies difficulty badges colored per actual level (Beginner/Intermediate/Advanced). The `_extractTodaysWorkouts` method always creates `_WorkoutInfo(difficulty: 'Intermediate')` regardless of actual program data. The schedule JSON may carry a `difficulty` or `intensity` field that is being ignored. | Read `day['difficulty']` or `day['intensity']` from the schedule JSON, falling back to `'Intermediate'` if absent. This directly affects visual correctness of AC-4. |
| M2 | `activity_rings_card.dart:164-183` | **`_ConnectHealthPrompt` has no tap handler and missing "Connect Health" text.** AC-5 and edge case #2 require: "Steps and activity rings show grayed-out tracks with a 'Connect Health' **tappable** link that re-triggers the health permission flow." The current widget shows only `'--'` and the label name — no "Connect Health" text and no `onTap`. | Make `_ConnectHealthPrompt` a `ConsumerWidget` (or accept a callback), add "Connect Health" tappable text styled as a chip/link, and wire it to `ref.read(healthDataProvider.notifier).requestOsPermission()` or to re-show `showHealthPermissionSheet`. |
| M3 | `home_screen.dart` (whole file) | **File is 233 lines, exceeding AC-1's <150 line requirement.** The `_DashboardContent` widget (lines 115-233, ~119 lines) is embedded in the orchestrator file. The `HomeScreen` class itself is ~113 lines. | Extract `_DashboardContent` and `_workoutWeekdays` to a separate `dashboard_content.dart` file. This brings `home_screen.dart` to ~113 lines, satisfying AC-1. |
| M4 | `todays_workouts_section.dart` & `health_metrics_row.dart` | **Both files exceed the 150-line-per-widget-file convention.** `todays_workouts_section.dart` is 191 lines; `health_metrics_row.dart` is 193 lines. The CLAUDE.md rule says "Max 150 lines per widget file." | For `todays_workouts_section.dart`: extract `_WorkoutInfo` and `_extractTodaysWorkouts` into a small helper/model file. For `health_metrics_row.dart`: extract `_HeartWavePainter` to its own file (it's a self-contained `CustomPainter`). |
| M5 | `activity_rings_card.dart:29,31` | **No "Nutrition goals not set" prompt when `caloriesGoal` is 0.** AC-5 edge case #3 says: "Calories ring shows 0/0 with a 'Set up nutrition goals' prompt. The ring track is fully dimmed." Currently when `caloriesGoal == 0`, the card shows `0 / 0 Cal` with no prompt. | Add a conditional: when `caloriesGoal == 0`, display centered text "Nutrition goals not set" inside the rings area (or below rings), matching the empty state spec. |
| M6 | `activity_ring_painter.dart:60` | **Progress is clamped to 1.0 but values > 1.0 are valid (e.g., eating over calorie goal).** The painter clamps `progress` to `[0.0, 1.0]`, and the card also clamps on lines 50-52. If a user exceeds their calorie goal (e.g., 1200/1000), the ring maxes at full but gives no visual indication of exceeding the goal. | This is acceptable behavior (a full ring = goal met or exceeded). Add a code comment noting this is intentional, or consider a subtle visual difference for >100% (e.g., a glow or a small "!" badge). Low priority. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `dashboard_header.dart:65` | `_TvModeButton()` lacks a `const` constructor despite having no fields. Prevents Flutter's const-widget optimization. | Add `const _TvModeButton();` constructor. |
| m2 | `workout_card.dart:40-43` | The `CustomPaint` for `_PatternPainter` is not wrapped in `RepaintBoundary`. Since each workout card has one, and the pattern is static (only depends on `accentColor`), unnecessary repaints occur on parent rebuild. | Wrap the `ClipRRect` containing `CustomPaint` in a `RepaintBoundary`. |
| m3 | `health_metrics_row.dart:183` | `_HeartWavePainter` iterates pixel-by-pixel (`x += 1`) to draw the sine wave. On wide screens this could be 200+ path segments per paint. | Increase step to `x += 2` — negligible visual difference, ~50% fewer path operations. |
| m4 | `weight_log_card.dart:50` | Weight conversion uses `* 2.205` but the precise factor is `2.20462`. For 100kg, the difference is 0.012 lbs — negligible but technically imprecise. | Use `2.20462`. |
| m5 | `dashboard_section_header.dart:31-51` | The "View All" action uses `GestureDetector` with no minimum touch target size. The text + chevron may be hard to tap on small screens. | Wrap in `SizedBox(height: 44)` or use `InkWell` with padding to meet the 44pt minimum touch target (Apple HIG). |
| m6 | `activity_ring_painter.dart:56` | At `progress == 1.0`, the rounded `StrokeCap` at the arc's start and end overlap at the 12 o'clock position, creating a visible bump/thickening. | For `progress >= 0.99`, draw a full circle with `drawCircle` instead of `drawArc`. |
| m7 | `leaderboard_teaser_card.dart:14` | Uses em-dash "—" in "Leaderboard — See where you rank" while the ticket spec shows a simple dash or no dash. | Confirm with design. Minor copy inconsistency. |
| m8 | `weight_log_card.dart:44-53` | Weight unit is hardcoded to lbs. Ticket (edge case #8) says: "Check `UserProfile.preferred_unit`... default to lbs if no preference." The current code doesn't read any user preference — it always converts to lbs. | Read `UserProfile.preferred_unit` from the auth state. If `metric` or `kg`, display in kg. Default to lbs. This is more properly a major issue but marked minor because the ticket says "default to lbs" for US-centric users. |
| m9 | `dashboard_header.dart:19` | `DateFormat('EEEE, MMM d').format(DateTime.now())` creates a new `DateTime.now()` each time the widget rebuilds. If the widget rebuilds at midnight, the date may be stale relative to other parts of the screen. | Minor — unlikely to matter in practice. Could accept a `DateTime` parameter for testability. |
| m10 | `home_screen.dart:229` | `catch (_)` in `_workoutWeekdays` — another silent catch violating the error handling rule. Invalid dates from `recentWorkouts` are silently ignored. | Add `assert(() { debugPrint('Invalid date in recentWorkouts: ${w.date}'); return true; }())` in the catch block. |

---

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1: File decomposition | **PARTIAL FAIL** | Orchestrator file is 233 lines (>150). `todays_workouts_section.dart` (191) and `health_metrics_row.dart` (193) also exceed 150. |
| AC-2: Greeting header | **PASS** | All elements present and correct. Fallback to "Hey there!" works. |
| AC-3: Week calendar strip | **PASS** | 7 days Sun-Sat, selected highlight, workout dots, tap handler. |
| AC-4: Today's Workouts | **PARTIAL** | Works structurally but difficulty is hardcoded (M1). |
| AC-5: Activity rings | **PARTIAL** | Rings render correctly. Missing "Connect Health" tappable prompt (M2) and "Nutrition goals not set" prompt (M5). |
| AC-6: Heart + Sleep cards | **PASS** | Matches spec. |
| AC-7: Weight log section | **PASS** | Weight display, conversion, empty state, CTAs all present. |
| AC-8: Existing cards preserved | **PASS** | All four preserved cards present in layout. |
| AC-9: All states handled | **PARTIAL** | Missing debounce (C3). Shimmer is subpar (C1). |
| AC-10: Riverpod only | **PASS** | Only `setState` is for ephemeral `_selectedDate`. |
| AC-11: Theme compliance | **PASS** | Colors centralized properly. |
| AC-12: Offline banner | **PASS** | Present at top of layout. |
| AC-13: FAB and navigation | **PASS** | FAB, TV mode, notifications all intact. |
| AC-14: Leaderboard teaser | **PASS** | Matches spec. |

---

## Security Concerns

None. No new API calls, no user input beyond date selection, no secrets.

## Performance Concerns

1. `_DashboardContent` rebuilds its entire subtree on any `HomeState` change. Acceptable but could benefit from more granular `select()` usage in the future.
2. `_PatternPainter` on each workout card lacks `RepaintBoundary` (m2).
3. `_HeartWavePainter` pixel-by-pixel iteration (m3) — minor.
4. `ActivityRingPainter` properly wrapped in `RepaintBoundary` — good.

---

## Quality Score: 7/10

The implementation is solid overall. The widget decomposition is clean and logical, the visual design matches the spec well, Riverpod usage is correct, and the code follows existing project patterns. The main gaps are: (1) silent error catching violating the project's error handling rule, (2) missing pull-to-refresh debounce explicitly called out in the ticket, (3) the "Connect Health" tappable prompt being absent, (4) hardcoded difficulty badges, (5) missing "Nutrition goals not set" empty state, and (6) three files exceeding the 150-line limit.

## Recommendation: REQUEST CHANGES

**Must fix before merge:** C1-C3 (shimmer quality, silent catches, debounce) and M1-M5 (hardcoded difficulty, Connect Health prompt, file length, nutrition goals empty state).

**Can defer:** M6 and all minor issues.
