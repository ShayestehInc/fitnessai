# Pipeline 32 Focus: Trainee Web Portal

## Priority
Build a full self-service web portal for trainees, enabling workout logging, nutrition tracking, program viewing, messaging, and progress charts from a browser. This is the single biggest gap: trainer, admin, and ambassador dashboards all exist on web — trainee has zero web access beyond a read-only impersonation view.

## Key Changes
- Web: New `(trainee-dashboard)` route group with trainee-facing layout, auth, and navigation
- Web: Home dashboard (today's workout, nutrition summary, weight trend, recent activity)
- Web: Program viewer (assigned program schedule, active workout logging with sets/reps tracking)
- Web: Nutrition logging (macro tracker, food search, AI parsing, weight check-in)
- Web: Progress page (weight trend chart, workout history, adherence stats)
- Web: Messaging (reuse existing messaging infrastructure from trainer side)
- Web: Settings (profile, password change, theme toggle)
- Backend: Ensure all trainee-facing API endpoints are compatible with web (CORS, cookie-based or JWT auth)

## Scope
- Trainee can log in to web with existing credentials and see a trainee-specific dashboard
- Trainee can view their assigned program and log workouts from browser
- Trainee can track nutrition (food logging, macro tracking) from browser
- Trainee can view progress charts (weight, volume, adherence)
- Trainee can send/receive messages with their trainer
- Trainee can view announcements and community feed
- Reuse existing API endpoints — no new backend work needed beyond any CORS/auth adjustments
