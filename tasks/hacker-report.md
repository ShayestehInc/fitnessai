# Hacker Report: Video Workout Layout

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | exercise-video-player.tsx | YouTube iframe `onError` | Error state shown when YouTube embed fails to load | No error handler on `<iframe>`. Only native `<video>` has `onError`. If a YouTube video is private, removed, or region-blocked, user sees a broken embed forever with no fallback. |
| 2 | Medium | _ExerciseCard (active_workout_screen.dart) | Play button when `videoUrl` is null | Tapping the play icon opens video or does nothing useful | A white circle with a play arrow icon renders even when there is no video. It is purely decorative — no `onTap` handler. Looks tappable but does nothing. |
| 3 | Low | video_workout_layout.dart | Drag handle on logging card | Dragging the handle resizes the card | The drag indicator bar is cosmetic only — no `DraggableScrollableSheet` or gesture wired up. User expects to drag it up/down. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 4 | High | video_workout_layout.dart:432-441 | Exercise name in top overlay has no width constraint — `maxLines: 1` + `TextOverflow.ellipsis` is set, but the `Column` child has unbounded width between two `Spacer`s. Long exercise names (e.g. "Single-Arm Dumbbell Romanian Deadlift") will overflow horizontally because `Text` in an unconstrained `Column` does not clip. | Wrap the center `Column` in `Flexible` or `Expanded` so it respects available width. |
| 5 | Medium | layout-config-selector.tsx | Layout option labels ("Classic", "Card", "Minimal", "Video") and descriptions are hardcoded English strings, not using `t()` i18n function | All four labels and descriptions should go through `t()`. The component already imports `useLocale`. |
| 6 | Medium | exercise-detail-panel.tsx | Multiple hardcoded English strings: "Edit Exercise", "Muscle Group", "Select muscle group", "No difficulty set", "Training Goals", "Suitable For", "Image", "Video", "Edit", "Cancel", "Save" — none use `t()` | Wrap all user-facing strings in `t()`. |
| 7 | Low | video_workout_layout.dart | Weight displayed as "Lb" (singular, capitalized inconsistently). Classic layout header says "LBS". Mixed unit terminology across layouts. | Standardize to one label ("lbs" or "lb") across all layouts; ideally make it configurable (kg vs lb). |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 8 | High | video_workout_layout.dart | 1. Start video workout. 2. Complete a set. 3. Rest timer starts. 4. Navigate to a different exercise via chevron/swipe during rest. | Rest timer should continue for the original exercise; video changes to new exercise. | Video changes correctly, but rest overlay blocks the entire video area. User cannot see the new exercise's video or interact with the logging card for the new exercise while rest is active. The rest timer is global, not per-exercise. |
| 9 | High | active_workout_screen.dart:64-72 | `_fetchLayoutConfig()` is async and runs in `initState`. | Layout is ready before workout starts. | There is a race: `_layoutType` defaults to `'classic'` and `_fetchLayoutConfig` runs asynchronously. If the API is slow, user may see classic layout flash before switching to video layout. No loading state while config is fetched. |
| 10 | High | video_workout_layout.dart:148-162 `_syncControllers` | 1. Start video workout with 3 exercises. 2. Add a set to exercise 2. 3. Navigate back to exercise 1. 4. Add a set to exercise 1. | Controllers grow to match sets for all exercises. | `_syncControllers` only *grows* the controller lists — it never shrinks them if `exerciseLogs` length decreases. More critically: if an exercise is removed mid-workout (edge case), `_weightControllers[i]` will access stale/wrong exercise data. Also, old controllers beyond the current set count are never disposed. |
| 11 | Medium | video_workout_layout.dart:169-204 `_initVideo` | 1. Rapidly swipe between exercises (each triggers `_initVideo`). | Each swipe cancels the prior video load and starts the new one cleanly. | Race condition: `_initVideo` is `async` but has no cancellation mechanism. If user swipes through 5 exercises quickly, 5 `controller.initialize()` calls run concurrently. The first to complete sets `_videoController`, but later completions may overwrite it or call `setState` after disposal. Only the `old` controller from the *start* of the call is disposed — intermediate ones leak. |
| 12 | Medium | exercise-video-player.tsx | `videoUrl` prop is typed as `string` (required), but parent (`exercise-detail-panel.tsx:371`) only renders when `exercise.video_url` is truthy. | If a caller passes an empty string, it falls through to `<video src="">`. | `extractYouTubeId("")` returns null, so an empty string creates a `<video src="">` which triggers `onError`. Not a crash, but wasteful and the error state is misleading ("Video unavailable" for an empty URL). |
| 13 | Medium | video_workout_layout.dart:207-210 `_toggleSpeed` | Toggle speed multiple times. | Smooth toggle between 0.5x and 1.0x. | Only two speed options (1.0x and 0.5x). No 0.75x or 1.5x. Minor, but the UI says "Speed" implying more options. Also, speed preference is not persisted — resets on every exercise change because `_initVideo` creates a fresh controller but does re-apply `_playbackSpeed`. This part actually works, but the `debugPrint` on line 194 and 201 will print to console in production (convention says no debug prints). |
| 14 | Low | active_workout_screen.dart:383-396 `_completeSet` | Complete a set on any layout. | Rest timer starts for the *current* exercise's rest period. | Rest timer always starts after every set completion, even the last set of the last exercise. Finishing the final set then triggers a rest timer that serves no purpose — user is about to hit Finish. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 15 | High | Video layout | Add a loading shimmer/skeleton while `_fetchLayoutConfig` is in flight, instead of defaulting to classic and switching. | Prevents a jarring layout flash on slow connections. |
| 16 | High | Video layout | Allow undo on completed sets. Currently once a set is marked complete, the inputs are disabled with no way to fix a typo. | Every fitness app (Strong, Hevy) allows editing completed sets. Users make input mistakes constantly. |
| 17 | Medium | Video layout | Add auto-advance to next exercise when all sets for current exercise are completed. | Reduces taps. Nike Training Club and Peloton auto-advance. |
| 18 | Medium | Web layout selector | Provide a live preview or animation of each layout option, not just an icon + text description. | Users picking "Video" have no idea what it looks like until they start a workout. |
| 19 | Medium | Video layout | The weight unit "Lb" is hardcoded. Should respect user profile unit preference (kg vs lb). | International users expect metric. |
| 20 | Low | Video layout | Keyboard opens and can obscure the logging card inputs. Consider `resizeToAvoidBottomInset: true` (already set) but the `maxHeight` constraint (35% of screen) may clip when keyboard is open. | On smaller phones, 35% minus keyboard leaves almost no visible card. |
| 21 | Low | Duplicate code | `_muscleGroupColor` and `_formatMuscleGroup` are duplicated verbatim in `video_workout_layout.dart` and `active_workout_screen.dart` (_ExerciseCard). | Extract to a shared utility to reduce drift risk. |

## Summary
- Dead UI elements found: 3
- Visual bugs found: 4
- Logic bugs found: 7
- Improvements suggested: 7
- Items fixed by hacker: 0

## Chaos Score: 4/10
