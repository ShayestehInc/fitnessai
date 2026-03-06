# Feature: TV Mode — Gym Display

## Priority
High

## User Story
As a trainee, I want to display my current workout on a gym TV or tablet so that I can easily see my exercises, sets, reps, and rest timer at a distance while training.

## Acceptance Criteria
- [ ] TV mode screen shows today's workout from the active program
- [ ] Each exercise is displayed with name, target sets x reps, and suggested weight (from last session)
- [ ] Current exercise is visually highlighted; completed exercises are checked off
- [ ] Rest timer with large countdown display (configurable: 30s, 60s, 90s, 120s, 180s)
- [ ] Rest timer starts when user taps "Complete Set" and auto-advances
- [ ] Overall workout progress bar (exercises completed / total)
- [ ] Elapsed workout time displayed
- [ ] Screen stays awake while TV mode is active (wakelock)
- [ ] Fonts are large enough to read at 10+ feet (48pt+ for numbers, 24pt+ for labels)
- [ ] High contrast dark theme for gym readability
- [ ] Empty state when no active program or today is a rest day
- [ ] Error state when program data fails to load
- [ ] Loading state while fetching workout data
- [ ] Back/exit button to leave TV mode
- [ ] Route wired in app_router.dart and accessible from trainee navigation

## Edge Cases
1. No active program assigned — show empty state with message
2. Today is a rest day — show rest day message with next workout preview
3. All exercises already completed — show completion celebration
4. Timer reaches zero — visual/audio pulse, auto-stop
5. User leaves TV mode mid-workout — timer stops, state preserved if they return
6. Program schedule has no exercises for today's day index — show empty state
7. Exercise has no previous weight data — show target reps/sets without weight suggestion
8. Very long exercise names — truncate with ellipsis, still readable

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| No program | "No workout assigned" + icon | Show empty state |
| Rest day | "Rest Day" + next workout info | Show rest state |
| Network error loading | "Could not load workout" + retry | Show error with retry button |
| All exercises done | "Workout Complete!" + stats | Show completion state |

## UX Requirements
- **Loading state:** Large centered spinner with "Loading workout..." text
- **Empty state:** Icon + "No workout today" message + suggestion to check program
- **Error state:** Icon + error message + retry button (large, tappable)
- **Success feedback:** Set completion animates the exercise check, progress bar advances
- **Mobile behavior:** Works in both portrait and landscape; landscape preferred for TV cast

## Technical Approach

### Files to create:
- `mobile/lib/features/tv/presentation/providers/tv_mode_provider.dart` — Riverpod provider for TV mode state (current exercise, completed sets, timer)
- `mobile/lib/features/tv/presentation/screens/tv_mode_screen.dart` — Main TV mode screen (replaces tv_screen.dart)
- `mobile/lib/features/tv/presentation/widgets/tv_exercise_card.dart` — Large exercise display card
- `mobile/lib/features/tv/presentation/widgets/tv_rest_timer.dart` — Large countdown timer widget
- `mobile/lib/features/tv/presentation/widgets/tv_progress_bar.dart` — Workout progress bar
- `mobile/lib/features/tv/presentation/widgets/tv_workout_header.dart` — Header with program name, elapsed time

### Files to modify:
- `mobile/pubspec.yaml` — Add `wakelock_plus` package
- `mobile/lib/core/router/app_router.dart` — Add TV mode route
- `mobile/lib/features/tv/presentation/screens/tv_screen.dart` — Replace placeholder (or redirect to tv_mode_screen)

### Dependencies:
- `wakelock_plus: ^1.2.8` — Keep screen awake
- Existing: `flutter_riverpod`, `go_router`, workout_provider (for program data)

### Key Design Decisions:
- Reuse `workoutStateProvider` to get active program and today's workout
- TV mode manages its own set-completion and timer state via separate provider
- Dark theme colors from AppTheme (already dark-mode-first)
- No network calls for set logging — TV mode is display/timer only, workout logging happens in the regular active workout screen

## Out of Scope
- Casting/Chromecast integration (future)
- Audio cues on timer completion (future, needs audio package)
- Landscape-only forced orientation (support both, prefer landscape)
- Syncing TV mode set completion with active workout screen
