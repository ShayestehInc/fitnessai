# Feature: Achievement Toast on New Badge

## Priority
High

## User Story
As a trainee, I want to see a celebratory toast/overlay when I earn a new achievement badge so that I feel rewarded and motivated to continue my fitness journey.

## Acceptance Criteria
- [ ] AC1: `NewAchievementModel` already exists in mobile — parse `new_achievements` from post-workout survey API response
- [ ] AC2: Parse `new_achievements` from weight check-in API response (backend needs to include it)
- [ ] AC3: Parse `new_achievements` from nutrition save API response (backend needs to include it)
- [ ] AC4: Achievement celebration overlay widget shows achievement icon (mapped from icon_name), name, and description
- [ ] AC5: Overlay has celebratory animation — scale-in with glow effect, pulsing badge icon
- [ ] AC6: Overlay auto-dismisses after 4 seconds, or user can tap to dismiss early
- [ ] AC7: If multiple achievements earned at once, show them sequentially (queue-based)
- [ ] AC8: Haptic feedback (success pattern) on achievement display
- [ ] AC9: Celebration overlay works from any screen (uses global overlay/navigator key)
- [ ] AC10: Offline workout submissions show achievements when synced (deferred — no achievement data available offline)

## Edge Cases
1. No achievements earned — no overlay shown, no errors
2. Single achievement earned — overlay shown once, auto-dismisses
3. Multiple achievements earned simultaneously — queued, shown one after another with brief delay
4. User navigates away during overlay — overlay dismissed cleanly, no orphaned widgets
5. Achievement icon_name not in icon map — falls back to default trophy icon (Icons.emoji_events)
6. API response missing new_achievements key — treated as empty list, no overlay
7. Achievement data malformed (missing name/description) — skip that achievement, log warning
8. User on slow device — animations use hardware-accelerated transforms only
9. Offline workout later syncs — sync handler does not have achievement data from server, skip toast
10. Weight check-in and nutrition endpoints currently don't return new_achievements — backend needs update

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| API returns no new_achievements | Nothing | No overlay triggered |
| Malformed achievement JSON | Nothing | Logs parse error, skips |
| Icon name not found | Default trophy icon | Falls back gracefully |
| User dismisses during animation | Overlay exits smoothly | Animation controller disposed |
| Multiple rapid API calls with achievements | Sequential toasts | Queue prevents overlap |

## UX Requirements
- **Celebration overlay**: Full-width card sliding down from top (like iOS toast but larger and more celebratory). Achievement icon in a glowing circle, achievement name in bold, description below. Gold/amber accent color for the glow effect.
- **Animation**: Scale-up entrance (0 to 1 with elastic curve). Subtle pulsing glow around the icon. Slide-up exit.
- **Haptic**: Success haptic pattern on show.
- **Timing**: 4-second display, 300ms entrance, 300ms exit. Sequential achievements have 500ms gap between them.
- **Dismiss**: Tap anywhere on the overlay to dismiss early. Swipe up to dismiss.
- **Accessibility**: VoiceOver/TalkBack announces "Achievement earned: [name]. [description]".
- **Theming**: Uses app theme colors. Gold accent for the badge glow (#FFD700 with opacity).

## Technical Approach

### Backend Changes (minor)
- `backend/workouts/views.py`: Weight check-in `perform_create` and nutrition save should return `new_achievements` in their response, same pattern as post-workout survey.

### Mobile Changes
- **New widget**: `achievement_celebration_overlay.dart` — the animated overlay widget
- **New service**: `achievement_toast_service.dart` — singleton queue manager using a global overlay key. Accepts `List<NewAchievementModel>`, queues them, shows sequentially.
- **Provider**: `achievement_toast_provider.dart` — Riverpod provider wrapping the service, exposed globally.
- **Wiring in active_workout_screen.dart**: After `_submitPostWorkoutSurvey`, parse `new_achievements` from `OfflineSaveResult.data` and trigger the toast.
- **Wiring in weight_checkin_screen.dart**: After successful check-in, parse `new_achievements` from response.
- **Wiring in nutrition provider/screen**: After successful nutrition save, parse `new_achievements` from response.
- **WorkoutRepository update**: `submitPostWorkoutSurvey` must forward `new_achievements` from response data.
- **OfflineSaveResult**: Already carries arbitrary `data` map — achievements will flow through.

### Files to create
- `mobile/lib/shared/widgets/achievement_celebration_overlay.dart`
- `mobile/lib/core/services/achievement_toast_service.dart`

### Files to modify
- `backend/workouts/views.py` — add new_achievements to weight check-in and nutrition responses
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` — forward new_achievements from API
- `mobile/lib/core/database/offline_workout_repository.dart` — already forwards data, may need new_achievements key
- `mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart` — trigger achievement toast
- `mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart` — trigger achievement toast
- `mobile/lib/features/community/presentation/widgets/achievement_badge.dart` — reuse icon map
- `mobile/lib/features/community/data/models/achievement_model.dart` — already has NewAchievementModel

## Out of Scope
- Web dashboard achievement toasts
- Push notification for achievements (separate feature)
- Confetti particle system (keep it clean and professional)
- Achievement sharing to social media
- Offline achievement calculation
