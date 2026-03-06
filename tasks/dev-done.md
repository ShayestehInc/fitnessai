# Dev Done: TV Mode — Gym Display

## Files Created
- `mobile/lib/features/tv/presentation/providers/tv_mode_provider.dart` — Riverpod StateNotifier for TV mode state (exercises, set completion, rest timer, elapsed time)
- `mobile/lib/features/tv/presentation/screens/tv_mode_screen.dart` — Main TV mode screen with loading/empty/error/complete/workout states
- `mobile/lib/features/tv/presentation/widgets/tv_exercise_card.dart` — Large exercise display card with completion status
- `mobile/lib/features/tv/presentation/widgets/tv_rest_timer.dart` — Large countdown timer with circular progress and configurable duration
- `mobile/lib/features/tv/presentation/widgets/tv_progress_bar.dart` — Workout progress bar
- `mobile/lib/features/tv/presentation/widgets/tv_workout_header.dart` — Header with program name, day, elapsed timer, exit button

## Files Modified
- `mobile/pubspec.yaml` — Added `wakelock_plus: ^1.2.8`
- `mobile/lib/core/router/app_router.dart` — Changed import from tv_screen to tv_mode_screen, added `/tv-mode` route using `adaptiveFullscreenPage`
- `mobile/lib/features/tv/presentation/screens/tv_screen.dart` — Converted to barrel file re-exporting tv_mode_screen
- `mobile/lib/features/home/presentation/screens/home_screen.dart` — Added TV mode icon button in header bar

## Key Decisions
- TV mode is display/timer only — does not write to backend. Workout logging happens in the regular active workout screen.
- Reuses `workoutStateProvider` for program data to avoid duplicate API calls.
- Own `tvModeProvider` (autoDispose) for set completion + rest timer state.
- Dark theme using existing AppTheme colors (zinc palette), high contrast.
- Screen stays awake via `wakelock_plus` enabled on mount, disabled on dispose.
- Sets landscape-preferred orientation but doesn't force it.
- Uses immersive sticky system UI mode for maximum screen space.
- Rest timer configurable: 30s, 60s, 90s, 120s, 180s (default 90s).
- Font sizes: 72pt for timer numbers, 48pt for completion, 32pt for set counts, 26pt for exercise names, 24pt+ for headers.

## Edge Cases Handled
- No active program: shows "No Program Assigned" with appropriate icon
- Rest day: shows "Rest Day" with next workout preview
- All exercises completed: shows celebration with stats (exercises, sets, duration)
- Empty exercises list: shows "No Workout Today"
- Timer reaches zero: auto-stops, removes rest overlay
- Long exercise names: truncated with ellipsis

## How to Test
1. Log in as a trainee with an active program
2. Tap the TV icon in the home screen header
3. Verify today's workout appears with large text
4. Tap "COMPLETE SET" — verify set counter advances and rest timer starts
5. Test rest timer skip button
6. Test duration selector (30s, 60s, etc.)
7. Complete all sets for all exercises — verify completion screen
8. Test with a trainee that has no program — verify empty state
9. Test on a rest day — verify rest day state
