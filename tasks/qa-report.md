# QA Report: Video Workout Layout

## Date: 2026-03-08

## Test Results
- Static Analysis (flutter analyze): 371 issues total (pre-existing), **0 errors** in video layout files
  - 1 minor `prefer_const_constructors` info in `exercise_video_player.dart:94`
- Backend: Verified by code inspection (no DB available for test suite)

## Acceptance Criteria Verification

- [x] Backend: `WorkoutLayoutConfig.LayoutType` includes `'video'` as valid choice -- **PASS** (`backend/trainer/models.py:270`: `VIDEO = 'video', 'Video'`)
- [x] Backend: Migration adds new choice without data loss -- **PASS** (`0008_alter_workoutlayoutconfig_layout_type.py` uses `AlterField` on choices only; no data migration, no column change, existing rows unaffected)
- [x] Backend: `GET /api/workouts/my-layout/` can return `layout_type: 'video'` -- **PASS** (`MyLayoutConfigView` in `survey_views.py:430-453` reads from `WorkoutLayoutConfig` model which now includes 'video' as a valid choice)
- [x] Backend: `PATCH /api/trainer/trainees/{id}/layout-config/` accepts `layout_type: 'video'` -- **PASS** (`TraineeLayoutConfigView` in `trainer/views.py:1456-1492` uses `WorkoutLayoutConfigSerializer` which validates against `LayoutType.choices`, now including 'video')
- [x] Web: Layout config selector shows 4 options (Classic, Card, Minimal, Video) -- **PASS** (`layout-config-selector.tsx:21-46`: `LAYOUT_OPTIONS` array has 4 entries, grid is `sm:grid-cols-4`)
- [x] Web: Video option has appropriate icon, label, description -- **PASS** (icon: `MonitorPlay`, label: `"Video"`, description: `"Full-screen exercise demo videos"`)
- [x] Web: Selecting Video persists to backend and shows as selected on reload -- **PASS** (mutation calls `apiClient.patch`, `onSuccess` invalidates query, `useEffect` syncs `selected` state from fetched `data.layout_type`)
- [x] Web: Exercise detail panel shows inline video player -- **PASS** (`exercise-detail-panel.tsx:371-373`: renders `<ExerciseVideoPlayer>` when `exercise.video_url` is truthy, in view mode)
- [x] Web: Video player loops, shows controls -- **PARTIAL PASS** (see Bug #1 -- native `<video>` has `loop` and `controls`, but YouTube embed does NOT have `loop=1` parameter)
- [x] Mobile: When backend returns `layout_type: 'video'`, VideoWorkoutLayout renders -- **PASS** (`active_workout_screen.dart:184-199`: `if (_layoutType == 'video')` renders `VideoWorkoutLayout`)

## Edge Cases

- [x] Exercise has no video_url -- fallback handled? -- **PASS** (Mobile: `_initVideo()` returns early if `url == null || url.isEmpty`, `_buildFallback()` shows gradient with muscle group color. Web: `exercise-detail-panel.tsx:371` conditionally renders player only when `exercise.video_url` is truthy)
- [x] YouTube URL + direct MP4 URL -- both handled? -- **PARTIAL PASS** (Web: `exercise-video-player.tsx:10-15` extracts YouTube ID and renders iframe, falls back to `<video>` for MP4. Mobile: `VideoPlayerController.networkUrl()` handles direct MP4 only; YouTube URLs will fail to initialize and show `_videoError=true` fallback icon -- see Bug #2)
- [x] Video fails to load -- error state shown? -- **PASS** (Web: `error` state shows `VideoOff` icon with "Video unavailable" text. Mobile: `_videoError=true` shows `Icons.videocam_off` icon in fallback gradient; workout logging continues unblocked)
- [x] Layout change mid-workout -- handled? -- **PASS** (`_fetchLayoutConfig()` runs once in `initState()` and caches `_layoutType` for the session. Layout only changes on next workout start as specified)
- [x] Old mobile app version -- falls through to classic default? -- **PASS** (`_buildExerciseContent` switch in `active_workout_screen.dart:371-380` has `default:` case that falls through to `ClassicWorkoutLayout`. `LayoutConfigModel.fromJson` defaults to `'classic'` if `layout_type` is null)

## Bugs Found

| # | Severity | Description |
|---|----------|-------------|
| 1 | Minor | Web: YouTube embed iframe in `exercise-video-player.tsx:41` does not include `loop=1` parameter. Acceptance criterion says "Video player loops" but YouTube embeds will not loop. Native `<video>` correctly has `loop`. Fix: change iframe src to include `?loop=1&playlist={ytId}`. |
| 2 | Medium | Mobile: `VideoWorkoutLayout` uses `VideoPlayerController.networkUrl()` which cannot play YouTube URLs. If a trainer sets a YouTube URL as the exercise video, the mobile video layout will show the error fallback (videocam_off icon) instead of the video. The web player handles this correctly with an iframe. Mitigated by graceful fallback -- workout logging is not blocked. |
| 3 | Medium | Web: `layout-config-selector.tsx:109` references i18n key `trainees.layoutDescription` which does NOT exist in any of the 3 locale files (en.json, es.json, pt-BR.json). This will render an empty string or a raw key depending on the i18n library's missing-key behavior. |
| 4 | Minor | Mobile: `video_workout_layout.dart` lines 195 and 201 contain `debugPrint()` calls. While `debugPrint` is stripped in release builds, the project convention says "No debug prints." These should be removed or replaced with a proper logger. |

## Confidence Level: HIGH

All 10 acceptance criteria pass or partially pass. The 2 medium bugs (YouTube on mobile, missing i18n key) are real but do not block the core feature. The YouTube issue on mobile is mitigated by a graceful fallback. The missing i18n key needs a quick fix to avoid showing a raw key or blank description to users.
