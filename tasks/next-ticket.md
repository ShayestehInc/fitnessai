# Feature: Trainer-Selectable Workout Layouts

## Priority
High

## User Story
As a trainer, I want to choose which workout logging UI each trainee sees (Classic table, Card swipe, or Minimal list), so that I can tailor the experience to each client's experience level and training style.

As a trainee, I want my active workout screen to use the layout my trainer selected, so that the UI matches my comfort level and training flow.

## Acceptance Criteria
- [ ] AC-1: Backend `WorkoutLayoutConfig` model exists with `trainee` (OneToOne → User), `layout_type` (classic/card/minimal, default: classic), `config_options` (JSONField), `configured_by` (FK → User trainer)
- [ ] AC-2: `GET /api/trainer/trainees/<id>/layout-config/` returns the trainee's current layout config (creates default if none exists)
- [ ] AC-3: `PUT /api/trainer/trainees/<id>/layout-config/` allows trainer to update layout_type for their trainee
- [ ] AC-4: `GET /api/workouts/my-layout/` returns the authenticated trainee's layout config
- [ ] AC-5: Trainer sees a "Workout Display" section in the trainee detail Overview tab with a segmented control to pick Classic / Card / Minimal
- [ ] AC-6: Changing the layout in trainer UI calls the API and shows success snackbar
- [ ] AC-7: Trainee's active workout screen renders the **Classic** layout: all exercises in a scrollable ListView, each with full sets table
- [ ] AC-8: Trainee's active workout screen renders the **Card** layout: current PageView one-exercise-at-a-time behavior (existing UI)
- [ ] AC-9: Trainee's active workout screen renders the **Minimal** layout: compact list with exercise name, set progress indicator, and quick-complete checkboxes
- [ ] AC-10: Default layout is "classic" for all existing trainees (no data migration needed — API returns classic when no config row exists)
- [ ] AC-11: Layout config survives app restart (fetched from API on workout screen load)
- [ ] AC-12: All three layouts produce identical workout data for the post-workout survey (same ExerciseLogState / SetLogState)
- [ ] AC-13: Only the trainee's trainer can update their layout config (row-level security)

## Edge Cases
1. **No WorkoutLayoutConfig exists for trainee**: API auto-creates one with `layout_type='classic'` on first GET
2. **Trainer updates layout while trainee is mid-workout**: No disruption — layout is read at workout start and cached for the session
3. **Trainee has no trainer (orphan)**: `my-layout` endpoint still works, returns 'classic' default
4. **Invalid layout_type in PUT request**: Backend validates against choices, returns 400
5. **Trainer tries to set layout for another trainer's trainee**: 404 (filtered by parent_trainer)
6. **config_options is null/empty**: Ignored — all layouts work with zero config_options initially
7. **Layout switch mid-session**: Not supported — layout determined at workout start. Trainer change takes effect on next workout.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Layout config API fails (trainee side) | Defaults to 'classic' layout silently | Logs warning, uses fallback |
| Layout config API fails (trainer side) | Error snackbar "Failed to update layout" | Shows error, keeps previous selection |
| Invalid layout_type submitted | 400 "Invalid layout type" | Django validation rejects |
| Unauthorized trainer tries to update | 404 not found | Queryset filters by parent_trainer |
| Network timeout fetching layout | Uses cached layout or 'classic' default | Retries once, then falls back |

## UX Requirements
- **Trainer side — Layout picker**: Section titled "Workout Display" between "Current Program" and "Quick Actions" in trainee detail Overview tab. Segmented control with three options: Classic (icon: table_chart), Card (icon: view_carousel), Minimal (icon: checklist). Each option has a small description below. Selecting triggers immediate API save + snackbar.
- **Loading state**: While fetching layout config, show the default 'classic' layout (no spinner needed — it's a fast single-row fetch)
- **Classic layout**: ScrollableListView of all exercises. Each exercise shows: exercise name + target sets/reps header, then the full sets table (SET/PREVIOUS/LBS/REPS/check). All exercises visible at once. Exercise sections separated by dividers. Sticky progress bar at top.
- **Card layout**: Current behavior — PageView.builder with one exercise per page. Swipe left/right. Exercise header with video area + sets table. This is the EXISTING `_ExerciseCard` widget.
- **Minimal layout**: Compact list. Each exercise is a collapsible tile: tap to expand and enter weight/reps. Collapsed shows exercise name + "3/4 sets done" progress text + circular progress indicator. Expanded shows simple weight/reps input rows without the large header/video area.
- **Success feedback (trainer)**: Snackbar "Layout updated to Classic" / "Layout updated to Card" / "Layout updated to Minimal"
- **All layouts**: Same timer functionality, same rest timer overlay, same progress indicator at top, same finish button

## Technical Approach

### Backend

**New model: `WorkoutLayoutConfig`** in `trainer/models.py`
```python
class WorkoutLayoutConfig(models.Model):
    class LayoutType(models.TextChoices):
        CLASSIC = 'classic', 'Classic'
        CARD = 'card', 'Card'
        MINIMAL = 'minimal', 'Minimal'

    trainee = models.OneToOneField('users.User', on_delete=models.CASCADE, related_name='workout_layout_config', limit_choices_to={'role': 'TRAINEE'})
    layout_type = models.CharField(max_length=20, choices=LayoutType.choices, default=LayoutType.CLASSIC)
    config_options = models.JSONField(default=dict, blank=True)
    configured_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='configured_layouts', limit_choices_to={'role': 'TRAINER'})
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

**New migration**: `trainer/migrations/0003_add_workout_layout_config.py`

**New serializer**: `WorkoutLayoutConfigSerializer` in `trainer/serializers.py`
- Fields: `layout_type`, `config_options`, `configured_by` (read-only), `updated_at` (read-only)

**New views** in `trainer/views.py`:
- `TraineeLayoutConfigView(RetrieveUpdateAPIView)`: GET/PUT for trainer → sets layout for their trainee
  - `get_queryset()`: filter by `trainee__parent_trainer=request.user`
  - `get_object()`: `get_or_create` with trainee from URL param

**New view** in `workouts/views.py` (or `survey_views.py`):
- `MyLayoutConfigView(RetrieveAPIView)`: GET for trainee → returns their own layout
  - Returns `{'layout_type': 'classic'}` default if no config exists

**New URLs**:
- `trainer/urls.py`: `path('trainees/<int:trainee_id>/layout-config/', TraineeLayoutConfigView.as_view())`
- `workouts/urls.py`: `path('my-layout/', MyLayoutConfigView.as_view())`

### Mobile

**New files:**
- `mobile/lib/features/workout_log/data/models/layout_config_model.dart` — simple model with `layoutType` string field
- `mobile/lib/features/workout_log/presentation/widgets/classic_workout_layout.dart` — all-exercises scrollable list with sets tables
- `mobile/lib/features/workout_log/presentation/widgets/minimal_workout_layout.dart` — collapsible compact list

**Modified files:**
- `mobile/lib/core/constants/api_constants.dart` — add layout config endpoints
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` — add `getMyLayout()` method
- `mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart` — switch between layout widgets based on layout_type
- `mobile/lib/features/trainer/data/repositories/trainer_repository.dart` — add `getTraineeLayout()` and `updateTraineeLayout()` methods
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — add layout picker section
- `mobile/lib/features/trainer/presentation/providers/trainer_provider.dart` — add layout config provider

**Key design:**
- The existing `_ExerciseCard` widget becomes the Card layout (extracted to `card_workout_layout.dart` is NOT needed — it stays inline as it is already self-contained)
- Classic layout: new widget that shows ALL exercises in a ListView with the same `_buildSetsTable` / `_buildSetRow` logic
- Minimal layout: new widget with `ExpansionTile` per exercise, compact set input rows
- All three layouts share the same `ExerciseLogState` / `SetLogState` data model and same `_completeSet` / `_addSet` callbacks

## Out of Scope
- Per-layout config_options (show_previous, auto_rest_timer) — model supports it but no UI for now
- Trainee self-selecting layout — trainer-only control
- Layout preview in trainer UI
- Workout layout analytics (which layout has better completion rates)
- Animations between layout switches
