# Dev Done: Video Workout Layout — End-to-End Activation

## Summary
Added 'video' layout type across the full stack: backend enum + migration, web layout config selector with video option, web exercise video player component, and mobile video-first workout layout widget.

## Files Changed

### Backend
- `backend/trainer/models.py` — Added `VIDEO = 'video', 'Video'` to `LayoutType` TextChoices, updated help_text
- `backend/trainer/migrations/0008_alter_workoutlayoutconfig_layout_type.py` — Auto-generated migration with updated help_text

### Web
- `web/src/components/trainees/layout-config-selector.tsx` — Added Video option; FIXED pre-existing bugs: values now match backend enum, field name corrected from `layout` to `layout_type`, localized description string
- `web/src/components/exercises/exercise-video-player.tsx` — New reusable player: YouTube embed detection + native video fallback. Added lazy loading, preload metadata, ARIA labels. Removed misleading iframe onError and duplicated JSX.
- `web/src/components/exercises/exercise-detail-panel.tsx` — Integrated ExerciseVideoPlayer

### Mobile
- `video_workout_layout.dart` — FIXED: exception logging, formatMuscleGroup guard, SystemChrome restore, swipe threshold
- `active_workout_screen.dart` — Wired up VideoWorkoutLayout
- `layout_config_model.dart` — Added isVideo getter

## Review Fixes Applied (Round 1)
- Critical #1-3: Web layout values/field name match backend, removed misleading iframe onError
- Major #4-9: YouTube regex expanded, dead code removed, exception logged, empty string guard, help_text updated, SystemChrome restored
- Minor #10-16: lazy loading, autoplay removed from allow, ARIA labels, deduplicated JSX, localized string, swipe threshold increased
