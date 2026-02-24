# Pipeline 34 Focus: Trainee Web — Trainer Branding Application

## Priority
Apply the trainer's white-label branding (app name, colors, logo) to the trainee web portal. The backend API exists at `/api/users/my-branding/` and returns the trainer's branding config. The trainee portal currently hardcodes "FitnessAI" everywhere and uses the default theme. This is the last remaining item to complete the white-label infrastructure.

## Key Changes
- Web: Create `useTraineeBranding()` hook to fetch branding from `/api/users/my-branding/`
- Web: Replace hardcoded "FitnessAI" with trainer's `app_name` in sidebar + mobile sidebar
- Web: Display trainer's logo in sidebar header when available
- Web: Apply trainer's `primary_color` as CSS custom property override for sidebar accent
- Backend: No changes needed — API already exists and works

## Scope
- Trainee web portal only (trainer/admin/ambassador dashboards unaffected)
- Branding = app_name + logo + primary_color + secondary_color
- Graceful fallback to defaults when no branding is configured
- No new backend endpoints needed
