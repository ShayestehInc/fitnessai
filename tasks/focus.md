# Pipeline 35 Focus: Trainee Web — Nutrition Tracking Page

## Priority
Build a dedicated Nutrition page in the trainee web portal with AI-powered meal logging, macro tracking with date navigation, meal history, and macro preset quick-select. The backend APIs all exist (`nutrition-summary`, `parse-natural-language`, `confirm-and-save`, `macro-presets`). The mobile app has full nutrition tracking. The trainee web portal only has a summary card on the dashboard — no way to actually log food or view meal history.

## Key Changes
- Web: Create `/trainee/nutrition` page with full macro tracking + meal logging
- Web: AI natural language food input (reuse existing `parse-natural-language` endpoint)
- Web: Meal history list with today's logged meals from nutrition_data
- Web: Date navigation (previous/next day) to view past nutrition
- Web: Macro preset quick-select for trainees
- Web: Add "Nutrition" link to trainee sidebar nav
- Backend: No changes needed — all APIs already exist

## Scope
- Trainee web portal only
- Reuse existing backend endpoints (no new API work)
- Match patterns from existing trainee web components (workout logging, dashboard cards)
- Graceful empty/loading/error states
- Mobile-responsive design
