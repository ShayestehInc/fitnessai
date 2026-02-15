# Pipeline 8 Focus: Trainee Workout History + Home Screen Recent Workouts

## Priority: HIGH

## What
Trainees log workouts daily but have zero way to review past sessions. No workout history screen, no workout detail view, no recent workouts on the home screen. The backend data exists (DailyLog.workout_data) but the mobile app has no way to surface it.

1. **Workout History Screen** — Paginated list of completed workouts (most recent first) with date, workout name, exercise count, total sets, and duration. Tappable for detail.
2. **Workout Detail Screen** — Full review of a logged workout: exercises with actual sets/reps/weights, readiness survey scores, post-workout survey data, timestamps.
3. **Home Screen "Recent Workouts"** — Section on trainee home showing last 3 completed workouts with quick stats. Tappable for detail.
4. **Backend Filtering** — New query params on DailyLog endpoint: `has_workout=true`, `ordering=-date`, pagination support.

## Why
- **Core value prop**: A fitness app where you can't review past workouts is fundamentally broken.
- **Motivation**: "I benched 225 last week, let me try 230 today" — requires seeing history.
- **Accountability**: Visible record of adherence drives consistency.
- **Trainee retention**: Users who can see their progress are more likely to stay engaged.

## Who Benefits
- **Trainees**: Can track progress, review past sessions, build on previous performance
- **Trainers**: Can reference trainee workout history during coaching conversations
- **Platform**: Increases daily engagement and retention metrics

## Success Metric
- Trainee opens app → sees "Recent Workouts" on home → taps to see full history → taps a workout → sees all logged exercises with weights/reps
