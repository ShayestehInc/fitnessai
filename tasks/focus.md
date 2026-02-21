# Pipeline 30 Focus: Macro Preset Management for Web Trainer Dashboard

## Priority
Add macro preset management to the web trainer dashboard so trainers can create, edit, delete, and copy nutrition presets for their trainees directly from the trainee detail page.

## Why This Feature
1. **Backend is fully built, web has zero UI** — The MacroPreset model, ViewSet with full CRUD, copy-to-trainee, and all-presets endpoints are fully implemented and tested. Mobile has a complete UI. The web dashboard has nothing.
2. **Trainers manage trainees on the web** — The web dashboard is the primary tool for trainee management. Trainers can already edit nutrition goals per-trainee, but cannot create or manage macro presets (Training Day, Rest Day, etc.).
3. **High workflow impact** — Trainers with 20+ trainees need presets to avoid manually entering macros for every trainee. Copy-to-trainee saves even more time.
4. **Completes the nutrition management gap** — The gap analysis identified this as the #1 missing feature on the web dashboard.
5. **Frontend-only work** — All API endpoints exist. This is purely a web frontend feature, following established patterns.

## Scope
- Web: Macro presets section in trainee detail Overview tab
- Web: Create/edit preset dialog with validation
- Web: Delete preset with confirmation
- Web: Copy preset to another trainee dialog
- Web: Set-as-default toggle
- Web: React Query hooks for all CRUD operations
- Web: URL constants for macro preset endpoints

## What NOT to build
- Backend changes (API is complete)
- Dedicated /macro-presets/ page (future enhancement)
- Bulk preset management across all trainees
- Mobile changes
- Preset templates library (global presets)
