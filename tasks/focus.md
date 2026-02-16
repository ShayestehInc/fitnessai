# Pipeline 17 Focus: Social & Community (Phase 7)

## Priority
Build the Phase 7 Social & Community features: trainer announcements, achievement/badge system, and trainee community feed.

## Phase 7 Items (from PRODUCT_SPEC.md)
1. Forums / community feed (trainee-to-trainee)
2. Trainer announcements (broadcast to all trainees)
3. Achievement / badge system
4. Leaderboards (opt-in, trainer-controlled)

## Scoping for This Pipeline
Given the scope, prioritize the highest-impact features for V1:

### Must Build (this pipeline)
1. **Trainer Announcements** — Trainer broadcasts messages to all their trainees. Backend model + API + mobile UI (trainer creates, trainee views on home screen). Push notification optional.
2. **Achievement / Badge System** — Define achievements (streak milestones, weight milestones, workout count, nutrition logging streaks). Backend model + earned tracking + mobile UI (badges on profile, toast on earn).
3. **Community Feed** — Trainee-to-trainee feed within a trainer's group. Post types: workout completion auto-posts, text posts, milestone celebrations. Like/reactions. Basic moderation (trainer can delete posts).

### Defer to Future Pipeline
4. **Leaderboards** — Requires opt-in privacy controls, ranking algorithms, and trainer configuration UI. Too complex for this pipeline alongside 3 other features.

## Context
- Backend: Django REST Framework with PostgreSQL
- Mobile: Flutter 3.0+ with Riverpod
- Existing models: User (with parent_trainer FK), TrainerNotification, DailyLog
- Existing patterns: ViewSet-based APIs, Riverpod StateNotifier providers, repository pattern
- The trainer already has a notification system (TrainerNotification model) — announcements are a new concept (trainer→trainees direction)
- No existing social/community infrastructure

## What NOT to build
- Real-time chat (too complex for V1 — use polling/pull-to-refresh)
- Image/video uploads in posts (text-only V1)
- Comment threads on posts (just likes/reactions for V1)
- Leaderboard rankings
- Push notifications for social features (use in-app only)
