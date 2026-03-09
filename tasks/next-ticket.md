# Feature: Trainee Dashboard Visual Redesign

## Priority
HIGH — The trainee home screen is the most-used screen in the app. A premium visual redesign directly impacts daily engagement and perceived product quality. This is the first screen every trainee sees every day.

## User Story
As a **trainee**, I want a visually premium, information-dense home dashboard so that I can see my workouts, nutrition, health metrics, and weight at a glance without scrolling through a wall of plain text cards.

## Background
The current `HomeScreen` is a 1,418-line monolith with a basic vertical card layout. The redesign transforms it into a premium dark-themed dashboard inspired by high-end fitness apps, with horizontal workout cards featuring images, Apple Watch-style activity rings, side-by-side health metric cards, a horizontal week calendar strip, and a quick weight log CTA. All data sources already exist — no backend changes needed.

---

## Acceptance Criteria

- [ ] **AC-1: File decomposition** — The current 1,418-line `home_screen.dart` is replaced by a slim orchestrator (<150 lines) that composes extracted widget files. Every new widget file is under 150 lines.
- [ ] **AC-2: Greeting header** — Shows "Hey, {firstName}!" (not "Hello,"), today's date formatted as "Saturday, Mar 8", user avatar (CircleAvatar with initials fallback), notification bell with unread badge, and "Coached by {trainerName}" subtitle when trainer exists.
- [ ] **AC-3: Week calendar strip** — Horizontal row of 7 days (Sun-Sat) for the current week. Each day shows abbreviated day name (SUN, MON...) and date number. Selected day (today by default) has a filled primary-color circle behind the date number. Days with completed workouts show a small dot indicator below the date. Tapping a day updates the selected date (visual only for now, no data filtering in this ticket).
- [ ] **AC-4: Today's Workouts section** — Horizontal scrollable list of workout cards. Each card is 200px wide x 240px tall with: a gradient overlay on a placeholder exercise image (use a dark gradient over a themed background pattern since we don't have real images yet), difficulty badge (colored: green=Beginner, amber=Intermediate, red=Advanced), workout name (bold, white), program name (muted), and a duration circle overlay (bottom-right, showing estimated minutes). If no workouts today (rest day), show the existing `RestDayCard` restyled to match. If no program assigned, show a "No program yet" empty state card with the same dimensions.
- [ ] **AC-5: Activity rings card** — Apple Watch-style triple concentric ring visualization. Outer ring = Calories (purple/violet, `0xFF8B5CF6`), middle ring = Steps (orange, `0xFFF97316`), inner ring = Active Minutes (green, `0xFF22C55E`). Each ring shows progress as a partial arc against a dimmed track. Below the rings: three stat columns showing "{consumed}/{goal} Cal", "{current}/{goal} Steps", "{current}/{goal} min Activity". Calories data comes from `HomeState.caloriesConsumed`/`caloriesGoal`. Steps and active calories come from `HealthMetrics`. Active minutes: derive from `HealthMetrics.activeCalories` using the rough conversion `activeCalories / 7` (approximate minutes). Goals: Calories from nutrition goals, steps default to 10,000, active minutes default to 60. The card gracefully degrades: if health data is unavailable, show only the calories ring with a "Connect Health" prompt for the other two.
- [ ] **AC-6: Heart + Sleep side-by-side cards** — Two equal-width cards in a `Row`. **Heart card:** Shows latest heart rate BPM from `HealthMetrics.heartRate` in large bold text, a small red heart icon, label "Heart Rate", and a decorative sine-wave line (static, purely visual). **Sleep card:** Shows a placeholder "-- h -- m" with a moon icon and label "Sleep" — sleep data is not yet available in `HealthMetrics`, so this card is a designed placeholder with a "Coming Soon" subtle label. Both cards use `AppTheme.card` background with 12px border radius.
- [ ] **AC-7: Weight log section** — Shows the latest weight from `HealthMetrics.latestWeightKg` (converted to user's preferred unit) with the date from `HealthMetrics.weightDate`. Includes a green down-arrow or red up-arrow trend indicator (compare to previous, or just show neutral dash if only one reading). Prominent "Weight In" CTA button (primary color, rounded) that navigates to the weight check-in screen. "View All" text button linking to weight trends. If no weight data, show empty state: "No weight logged yet" with the CTA button.
- [ ] **AC-8: Existing cards preserved** — `PendingCheckinBanner`, `ProgressionAlertCard`, `HabitsSummaryCard`, `RestDayCard`, and `QuickLogCard` are still rendered in the dashboard. They may be repositioned but must not be removed or broken.
- [ ] **AC-9: All states handled** — Loading state shows shimmer/skeleton placeholders for each section. Error state shows a retry banner at the top with the error message. Empty states are defined per-section (see AC-4, AC-5, AC-7). Pull-to-refresh reloads all data.
- [ ] **AC-10: Riverpod only** — No `setState` usage for data. All data reads use `ref.watch`. Only ephemeral UI state (animation controllers, scroll controllers) may use `setState`.
- [ ] **AC-11: Theme compliance** — All colors reference `AppTheme` constants or the new dashboard-specific color constants defined in a single file. No hardcoded color literals scattered across widget files. Font sizes use the theme's `TextTheme` or explicitly defined constants.
- [ ] **AC-12: Offline banner preserved** — The `OfflineBanner` and `SyncStatusBadge` continue to work as before.
- [ ] **AC-13: FAB and navigation preserved** — The floating action button (Android) and iOS header log button continue to navigate to `/ai-command`. All existing navigation (settings, TV mode, announcements, logbook, workout history) still works.
- [ ] **AC-14: Leaderboard teaser** — A simple "Leaderboard" card at the bottom showing a trophy icon and "See where you rank" text, tapping navigates to `/community/leaderboard`. This is a teaser card, not the full leaderboard.

---

## Edge Cases

1. **No program assigned** — "Today's Workouts" section shows an empty-state card ("No program assigned. Ask your trainer to set one up.") instead of crashing or showing blank space. Activity rings still show calories from nutrition data.
2. **Health data permission denied** — Activity rings card shows only the calories ring (from nutrition API). Steps and activity rings show grayed-out tracks with a "Connect Health" tappable link that re-triggers the health permission flow. Heart card shows "--" BPM. Weight section falls back to API weight data if HealthKit weight is unavailable.
3. **No nutrition goals set** — Calories ring shows 0/0 with a "Set up nutrition goals" prompt. The ring track is fully dimmed.
4. **User has no first name** — Greeting falls back to "Hey there!" instead of "Hey, !" or "Hey, null!".
5. **Extremely long workout/program names** — Text is truncated with ellipsis. Workout card name limited to 2 lines max. Program name limited to 1 line.
6. **All 7 days are rest days this week** — "Today's Workouts" shows the restyled RestDayCard. Calendar strip shows no workout dots for any day.
7. **Network error on initial load** — Full-screen error state with retry button. Does NOT show empty skeleton indefinitely.
8. **Weight unit conversion** — If user profile specifies imperial, convert kg to lbs for display. Default to lbs if no preference set (US-centric user base).
9. **Zero steps / zero calories at midnight** — Rings show 0 progress (empty arcs), not "no data." The card is still visible and correctly formatted with "0/10,000 Steps" etc.
10. **Pull-to-refresh while already loading** — Debounce: if `isLoading` is already true, the refresh callback should not trigger a duplicate load.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network failure on dashboard load | "Couldn't load your dashboard" banner with "Retry" button at top of screen. Cached/stale data (if any) still shown below. | `HomeState.error` set to error message. Loading state cleared. |
| Health data fetch fails | Activity rings show calories only. Heart/Sleep cards show "--" values. No crash. | `HealthDataState` remains in previous state. Error logged. |
| Nutrition API fails | Calories ring shows "No data" centered inside. Macro section hidden. | `nutritionGoals` and `todayNutrition` remain null. |
| Weight API/HealthKit fails | Weight section shows "No weight data" with the "Weight In" CTA still visible. | Graceful null handling on `latestWeightKg`. |
| User object missing (edge case) | Greeting shows "Hey there!" — no crash. | Null-safe access on `authState.user`. |

---

## UX Requirements

### Loading State
- Shimmer skeleton placeholders matching the exact layout of each section:
  - Header: two gray bars (greeting + date) and a circle (avatar)
  - Calendar strip: 7 small gray rounded rects
  - Workout cards: 2 gray rounded rects (200x240) in a horizontal row
  - Activity rings: a gray circle (160px diameter) with 3 small gray bars below
  - Heart + Sleep: two side-by-side gray rounded rects
  - Weight: one gray rounded rect
- Skeleton uses `AppTheme.zinc800` for the placeholder shapes with a subtle shimmer animation (lighter zinc700 sweep)

### Empty State (per section)
- **No program:** Card with dashed border, icon of a dumbbell, text "No program assigned", sub-text "Your trainer will assign one soon"
- **No nutrition goals:** Inside activity rings card, centered text "Nutrition goals not set" with dimmed ring tracks
- **No health data:** Rings for steps/activity show dimmed tracks; "Connect Health" chip/button
- **No weight:** "No weight logged yet" text + "Weight In" button (still prominent)
- **No workouts completed this week:** Calendar dots are absent. No special empty state needed.

### Error State
- Top-of-scroll error banner: `AppTheme.destructive` background with white text and "Retry" button
- Individual section errors: section shows a muted "Couldn't load" text with a small retry icon-button
- Never show a raw exception/stack trace

### Success Feedback
- Pull-to-refresh shows platform-native refresh indicator (already handled by `AdaptiveRefreshIndicator`)
- Weight In navigation: standard `context.push` — no snackbar needed from the dashboard itself

### Mobile Behavior
- All horizontal scroll sections use `BouncingScrollPhysics` on iOS, `ClampingScrollPhysics` on Android (use existing `adaptiveScrollPhysics`)
- Safe area insets respected (already handled)
- Content scrolls vertically with the existing `SingleChildScrollView` inside `AdaptiveRefreshIndicator`

---

## Technical Approach

### Files to Create

| File | Purpose | Max Lines |
|------|---------|-----------|
| `mobile/lib/features/home/presentation/widgets/dashboard_header.dart` | Greeting, date, avatar, notification bell, coach badge | ~120 |
| `mobile/lib/features/home/presentation/widgets/week_calendar_strip.dart` | Horizontal 7-day calendar with selection state | ~140 |
| `mobile/lib/features/home/presentation/widgets/todays_workouts_section.dart` | Section header + horizontal scrollable workout cards | ~80 |
| `mobile/lib/features/home/presentation/widgets/workout_card.dart` | Individual workout card with gradient, badge, duration circle | ~130 |
| `mobile/lib/features/home/presentation/widgets/activity_rings_card.dart` | Triple concentric ring painter + stat row | ~140 |
| `mobile/lib/features/home/presentation/widgets/activity_ring_painter.dart` | `CustomPainter` for the three concentric arcs | ~100 |
| `mobile/lib/features/home/presentation/widgets/health_metrics_row.dart` | Side-by-side Heart + Sleep cards | ~120 |
| `mobile/lib/features/home/presentation/widgets/weight_log_card.dart` | Latest weight, trend arrow, "Weight In" CTA | ~120 |
| `mobile/lib/features/home/presentation/widgets/leaderboard_teaser_card.dart` | Trophy icon + "See where you rank" CTA | ~60 |
| `mobile/lib/features/home/presentation/widgets/dashboard_shimmer.dart` | Full-screen shimmer skeleton layout | ~130 |
| `mobile/lib/features/home/presentation/widgets/dashboard_error_banner.dart` | Error banner with retry | ~50 |
| `mobile/lib/features/home/presentation/widgets/dashboard_section_header.dart` | Reusable section header with optional "View All" action | ~40 |
| `mobile/lib/features/home/presentation/constants/dashboard_colors.dart` | Dashboard-specific color constants (ring colors, badge colors, gradients) | ~40 |

### Files to Modify

| File | Change |
|------|--------|
| `mobile/lib/features/home/presentation/screens/home_screen.dart` | **Full rewrite** — Slim orchestrator (<150 lines) composing all section widgets. All private `_build*` methods removed, replaced by widget imports. |
| `mobile/lib/features/home/presentation/providers/home_provider.dart` | Add `selectedDate` to `HomeState` for calendar strip. Add workout-completed-days data (from `recentWorkouts` dates). No new API calls. |
| `mobile/lib/features/home/presentation/widgets/habits_summary_card.dart` | Minor restyle to match new card aesthetic (border radius 12, card background) |
| `mobile/lib/features/home/presentation/widgets/quick_log_card.dart` | Minor restyle to match new card aesthetic |
| `mobile/lib/features/home/presentation/widgets/pending_checkin_banner.dart` | Minor restyle to match new card aesthetic |
| `mobile/lib/features/home/presentation/widgets/progression_alert_card.dart` | Minor restyle to match new card aesthetic |

### Files Unchanged
- `mobile/lib/core/theme/app_theme.dart` — No changes; new colors go in `dashboard_colors.dart`
- `mobile/lib/core/router/app_router.dart` — No new routes needed
- All backend files — Zero changes

### Dependencies
- No new packages. The `CustomPainter` for activity rings is hand-rolled using Flutter's `Canvas` API.
- Shimmer effect: use a simple `AnimatedBuilder` + `LinearGradient` sweep. Do NOT add a new package.

### Key Design Decisions

1. **No real workout images** — We don't have exercise images in the data model. Workout cards use a dark gradient over a subtle themed background pattern (e.g., a faint grid or geometric shapes drawn with Canvas) to look premium without requiring assets. The gradient uses the program's or difficulty's accent color.
2. **Activity rings are a CustomPainter** — Not a package. Three concentric arcs with rounded stroke caps, drawn on a Canvas. Track (dimmed) + progress (bright) for each ring. This gives full control over sizing and animation.
3. **Sleep card is a placeholder** — `HealthMetrics` does not have sleep data. The card is designed and laid out but shows "--h --m" and a subtle "Coming Soon" label. This avoids a jarring empty space and sets up the UI for when sleep data is added.
4. **Calendar strip is visual-only** — Tapping a day updates a local `selectedDate` but does NOT re-fetch data for that date. Data filtering by date is a future ticket. The strip exists to establish the UX pattern and show workout-completion dots.
5. **Weight unit conversion** — Check `UserProfile.preferred_unit` (if it exists) or default to lbs. The conversion is `kg * 2.205`.

---

## Section-by-Section Visual Specification

### 1. Dashboard Header
```
+----------------------------------------------+
| Hey, Chris!                    [TV] [bell][av]|
| Saturday, Mar 8                               |
| * Coached by Sarah                            |
+----------------------------------------------+
```
- Greeting: `headlineLarge` (22px, w600), color `AppTheme.foreground`
- Date: `bodyMedium` (14px), color `AppTheme.mutedForeground`
- Coach line: `titleSmall` (12px, w500), color `AppTheme.primary`
- Avatar: 36px CircleAvatar, top-right. Initials fallback on `AppTheme.primary` bg.
- Notification bell: `Icons.notifications_outlined`, 24px. Badge uses `AppTheme.destructive` bg, white text, 16px diameter.
- Padding: 16px horizontal, 8px vertical

### 2. Week Calendar Strip
```
+----------------------------------------------+
|  SUN   MON   TUE   WED   THU   FRI   SAT    |
|   2     3     4     5    [6]    7     8       |
|                    .           .              |
+----------------------------------------------+
```
- Container: `AppTheme.card` background (`0xFF18181B`), 12px border radius, 12px vertical padding
- Day labels: `labelSmall` (10px), color `AppTheme.mutedForeground`, all-caps
- Date numbers: `titleMedium` (14px, w500), color `AppTheme.foreground`
- Selected date: Circle behind number using `AppTheme.primary` (`0xFF6366F1`), number becomes white
- Workout dot: 4px diameter circle, `AppTheme.primary`, 4px below date number
- Each day column: centered, equal flex, 48px touch target

### 3. Today's Workouts
```
+----------------------------------------------+
| Today's Workouts                    View All  |
| +---------+ +---------+ +---------+          |
| | gradient | | gradient | | gradient | <-scroll|
| |         | |         | |         |          |
| |[Intermd]| |[Beginr] | |[Advancd]|          |
| |Push Day | |Pull Day | |Leg Day  |          |
| |PPL Prog | |PPL Prog | |PPL Prog |          |
| |    (45) | |    (40) | |    (50) |          |
| +---------+ +---------+ +---------+          |
+----------------------------------------------+
```
- Card: 200w x 240h, 16px border radius, `AppTheme.card` base
- Gradient: bottom-to-top `LinearGradient` from `Colors.black.withOpacity(0.85)` to `Colors.transparent`
- Background: subtle geometric pattern using difficulty accent color at 10% opacity
- Difficulty badge: rounded rect, 6px vertical / 10px horizontal padding. Colors: Beginner `0xFF22C55E`, Intermediate `0xFFF59E0B`, Advanced `0xFFEF4444`. Text: 10px, bold, white.
- Workout name: `titleMedium` (14px, w600), white, max 2 lines, ellipsis
- Program name: `labelMedium` (12px), `AppTheme.mutedForeground`, max 1 line
- Duration circle: 40px diameter, `AppTheme.primary` at 80% opacity, white text (14px bold), positioned bottom-right with 12px inset
- Horizontal scroll: 12px gap between cards, 16px leading/trailing padding
- Card tap: navigates to active workout screen

### 4. Activity Rings Card
```
+----------------------------------------------+
|             ( ( ( ) ) )                       |
|          outer  mid  inner                    |
|                                               |
|  706/1,000 Cal   7,785/10,000    48/60 min   |
|   * Calories       * Steps       * Activity  |
+----------------------------------------------+
```
- Card: full width, `AppTheme.card` background, 16px border radius, 20px padding
- Ring diameters: outer 160px, middle 120px, inner 80px
- Stroke width: 12px for each ring
- Track color: ring color at 20% opacity
- Progress color: ring color at 100% opacity with rounded `StrokeCap.round`
- Ring colors: Calories `0xFF8B5CF6` (violet), Steps `0xFFF97316` (orange), Activity `0xFF22C55E` (green)
- Stat columns: evenly spaced Row below rings, 12px gap from rings
  - Value: `titleSmall` (12px, w500), `AppTheme.foreground`, number-formatted with commas
  - Label: `labelSmall` (10px), `AppTheme.mutedForeground`
  - Color dot: 8px circle matching ring color, left of label

### 5. Heart + Sleep Row
```
+---------------------+ +---------------------+
| Heart Rate          | | Sleep               |
|                     | |                     |
|     72              | |   -- h -- m         |
|     BPM             | |                     |
|  ~~~~~~~~~~~~~      | |  [colored bar]      |
|                     | |   Coming Soon       |
+---------------------+ +---------------------+
```
- Each card: flex 1, `AppTheme.card` background, 12px border radius, 16px padding, 12px gap between them
- Heart icon: `Icons.favorite`, `0xFFEF4444`, 16px
- BPM value: `displaySmall` (24px, bold), `AppTheme.foreground`
- "BPM" label: `labelMedium` (12px), `AppTheme.mutedForeground`
- Waveform: a `CustomPainter` drawing a simple sine wave path, stroke color `0xFFEF4444` at 60%, 2px stroke width, 30px tall
- Sleep icon: `Icons.nightlight_round`, `0xFF8B5CF6`, 16px
- Sleep value: `displaySmall` (24px, bold), `AppTheme.zinc500` (placeholder gray)
- Timeline bar: horizontal rounded rect (full width, 8px tall) with gradient placeholder segments in `AppTheme.zinc700`
- "Coming Soon": `labelSmall` (10px), `AppTheme.zinc500`, italic

### 6. Weight Log Card
```
+----------------------------------------------+
| Weight Log                         View All > |
|                                               |
|   185.4 lbs  v 0.6          [Weight In]      |
|   Mar 7, 2026 at 8:15 AM                     |
+----------------------------------------------+
```
- Card: full width, `AppTheme.card` background, 12px border radius, 16px padding
- Weight value: `headlineMedium` (20px, w600), `AppTheme.foreground`
- Unit: `bodyMedium` (14px), `AppTheme.mutedForeground`, inline after value
- Trend arrow: `Icons.trending_down` in `0xFF22C55E` (green = loss) or `Icons.trending_up` in `0xFFEF4444` (red = gain) or `Icons.trending_flat` in `AppTheme.zinc500` (neutral)
- Change amount: `bodySmall` (12px), same color as arrow
- Date: `labelMedium` (12px), `AppTheme.mutedForeground`
- "Weight In" CTA: `ElevatedButton` with `AppTheme.primary` bg, white text, 8px border radius, navigates to weight check-in
- "View All": text button, `AppTheme.primary` color, navigates to weight trends

### 7. Leaderboard Teaser
```
+----------------------------------------------+
|  (trophy)  Leaderboard - See where you rank > |
+----------------------------------------------+
```
- Card: full width, `AppTheme.card` background, 12px border radius, 12px vertical / 16px horizontal padding
- Trophy: `Icons.emoji_events`, `0xFFF59E0B` (amber), 24px
- Text: `titleMedium` (14px, w500), `AppTheme.foreground`
- Arrow: `Icons.chevron_right`, `AppTheme.mutedForeground`
- Entire card is tappable, navigates to `/community/leaderboard`

---

## Section Order (Top to Bottom)

1. `OfflineBanner` (conditional)
2. `DashboardHeader` (greeting, date, avatar, bells)
3. `WeekCalendarStrip`
4. `PendingCheckinBanner` (conditional)
5. `ProgressionAlertCard` (conditional)
6. `TodaysWorkoutsSection` (horizontal cards or rest day or empty state)
7. `QuickLogCard`
8. `ActivityRingsCard`
9. `HabitsSummaryCard`
10. `HealthMetricsRow` (Heart + Sleep side-by-side)
11. `WeightLogCard`
12. `LeaderboardTeaserCard`
13. 80px bottom spacer (for FAB clearance)

---

## Out of Scope

- **Date-based data filtering** — Tapping a calendar day only changes the visual selection. Fetching data for a past/future date is a separate ticket.
- **Real workout images** — Exercise model does not have image URLs yet. Use gradient + pattern backgrounds.
- **Real sleep data** — `HealthMetrics` does not include sleep. The Sleep card is a placeholder.
- **Leaderboard implementation** — The teaser card links to the existing leaderboard route. No new leaderboard UI in this ticket.
- **Animations** — Ring fill animations and card entrance animations are nice-to-have. If time permits, add a simple `TweenAnimationBuilder` on the rings. But functional correctness comes first.
- **Backend changes** — Zero. All data is already available via existing providers.
- **New packages** — Do not add any new pub dependencies.
- **Weight trend comparison** — The trend arrow (up/down) requires comparing to a previous weight. If only one weight exists, show the neutral flat icon. Full trend calculation is out of scope.
- **Internationalization of new strings** — New UI strings should use the l10n system where practical, but adding every new string to l10n JSON is not a hard requirement for this ticket. A follow-up i18n sweep can handle it.
