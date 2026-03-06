# Focus: TV Mode — Full Implementation

## Priority
High — Replacing placeholder with full gym display feature.

## Context
TV Mode is a gym screen display designed to be cast/displayed on a gym TV or tablet while training. The existing placeholder just shows "Coming Soon". The trainee's active program and today's workout data are already available via the workout provider.

## Scope
- Mobile only: No backend changes needed
- Replace placeholder TV screen with full gym display
- Show current day's workout in large, readable format
- Add rest timer with configurable duration
- Progress tracking through workout
- Screen wakelock (keep screen on)
- Dark theme optimized for gym display readability at distance

## Success Criteria
- TV mode shows today's exercises with sets/reps/weight in large format
- Rest timer counts down between sets with large visible countdown
- Progress bar shows completion through workout
- Screen stays awake while in TV mode
- Usable at 10+ feet distance (large fonts, high contrast)
- Works in both portrait and landscape
