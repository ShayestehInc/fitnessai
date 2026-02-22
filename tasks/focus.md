# Pipeline 33 Focus: Trainee Web — Workout Logging & Progress Tracking

## Priority
Make the trainee web portal interactive. Currently it's entirely read-only — trainees can view their assigned program, see nutrition macros, and read announcements, but cannot log workouts, record weight, or view historical progress. This pipeline adds the core interactive features that make the web portal actually useful for daily training.

## Key Changes
- Web: Weight check-in dialog (record weight from dashboard)
- Web: Active workout logging (start workout → log sets/reps/weight → complete → save to DailyLog)
- Web: Workout history page with completed workout details
- Web: Progress page with weight trend chart, workout volume chart, and adherence stats
- Backend: No new endpoints needed — all trainee APIs already exist

## Scope
- Trainee can record a weight check-in from the web dashboard
- Trainee can start a workout from their program schedule, log sets/reps/weight for each exercise, and save the completed workout
- Trainee can view their workout history with exercise details
- Trainee can view progress charts (weight trend, workout volume, weekly adherence)
- All backend APIs already exist — this is purely frontend work
- Reuse existing trainee API endpoints and hooks where possible
