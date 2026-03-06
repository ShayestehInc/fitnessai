# Focus: Achievement Toast on New Badge

## Priority
High — Completing partial feature from PRODUCT_SPEC. Backend already returns new_achievements data; mobile toast wiring needed.

## Context
Backend achievement system is complete: Achievement/UserAchievement models, achievement_service.py checks and awards badges after workout completion, weight check-in, and nutrition logging. The post-workout survey API response already includes `new_achievements` data. Mobile has full achievement screen, badge widget, model, repository, and provider. The missing piece is: showing a celebratory toast/overlay when achievements are newly earned.

## Scope
- Mobile only: No backend changes needed
- Parse `new_achievements` from API responses (post-workout survey, weight check-in, nutrition save)
- Show animated achievement celebration overlay
- Sequential display for multiple achievements
- Haptic feedback on celebration

## Success Criteria
- After completing a workout that earns a badge, user sees animated achievement toast
- Toast shows achievement icon, name, and description
- Multiple achievements display sequentially
- Auto-dismisses after a few seconds, tap to dismiss early
- Works for workout, weight check-in, and nutrition triggers
