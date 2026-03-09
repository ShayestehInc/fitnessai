# Focus: Trainee Dashboard Redesign

## Priority
HIGH — The trainee home screen is the most-used screen in the app. A premium visual redesign directly impacts daily engagement and perceived product quality.

## Inspiration
Dark fitness app dashboard (reference screenshot) featuring:
1. **Greeting header** with avatar, date, XP/gamification badge, notification bell
2. **Horizontal week calendar strip** — scrollable days with selected day highlighted (blue border), dots for activity
3. **Today's Workouts** — horizontal scrollable workout cards with exercise images, difficulty badges (Intermediate/Beginner), workout name, program name, duration circle overlay
4. **Activity rings** — Apple Watch-style concentric rings for calories, steps, and activity minutes with progress against daily goals
5. **Health cards** — Heart rate (BPM with waveform) + Sleep (duration with timeline bar) side-by-side
6. **Weight Log** — Recent weight entry with date/time, weight value, "Weight in" CTA button, "View all" link
7. **Leaderboard** — Community ranking teaser at bottom

## What Already Exists
- Home screen at `mobile/lib/features/home/presentation/screens/home_screen.dart` (1,418 lines)
- Nutrition rings (calorie + macros) — need to become activity rings style
- Health data integration (HealthKit/Health Connect) for steps, sleep, HR
- Weight check-in API and separate trends screen
- Weekly progress data
- Program + next workout display
- Leaderboard API at `/api/community/leaderboard/`
- All backend APIs are ready — no new endpoints needed

## Key Constraint
This is a VISUAL REDESIGN of the existing home screen, not a feature addition. All data sources already exist. Focus on:
- Premium dark theme aesthetic matching the inspiration
- Better visual hierarchy and information density
- Horizontal week calendar for date navigation
- Apple Watch-style activity rings
- Workout cards with images instead of plain text
- Side-by-side health metric cards
- Weight log with quick entry CTA
