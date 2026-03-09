# Feature: Progress Photos — Critical Bug Fixes & Web Dashboard

## Priority
HIGH — The progress photos feature is partially built but has 4 critical bugs that make the trainer flow completely broken, and has zero web dashboard support. Every fitness app needs working progress photos — trainers use them to assess client body composition changes.

## User Story
As a **trainer**, I want to view my trainees' progress photos from both mobile and web so that I can assess their body composition changes over time and provide better coaching.

As a **trainee**, I want to upload and compare my progress photos with working category filters so that I can track my physical transformation accurately.

## Acceptance Criteria

### Mobile Bug Fixes
- [ ] AC-1: Gallery category filter tabs show "All / Front / Side / Back" (not 4x "All")
- [ ] AC-2: Add Photo category options show "Front / Side / Back / Other" (not duplicate "Side")
- [ ] AC-3: When trainer navigates from trainee detail to progress photos with `trainee_id`, they see that trainee's photos (not their own empty gallery)
- [ ] AC-4: Measurements are sent as proper JSON object to the API (not `.toString()` string representation)
- [ ] AC-5: Trainer viewing trainee photos cannot delete them (read-only view)
- [ ] AC-6: Gallery shows "X's Progress Photos" when trainer is viewing a trainee's photos
- [ ] AC-7: Add Photo FAB is hidden when trainer is viewing trainee photos (trainee uploads their own)

### Web Dashboard — Trainee Progress Photos Page
- [ ] AC-8: Trainee web portal has "Progress Photos" nav link in sidebar
- [ ] AC-9: Trainee progress photos page shows photo grid grouped by date
- [ ] AC-10: Category filter tabs (All / Front / Side / Back) filter the grid
- [ ] AC-11: Click photo opens detail dialog with full-size image and measurements
- [ ] AC-12: "Add Photo" button opens upload dialog with file input, category selector, date picker, measurements form, notes
- [ ] AC-13: Upload sends multipart form data and refreshes grid on success
- [ ] AC-14: Delete button on photo detail dialog with confirmation
- [ ] AC-15: "Compare" button opens comparison view with two photo selectors and side-by-side display
- [ ] AC-16: Measurement diffs displayed in comparison view (e.g., "Waist: -3 cm")

### Web Dashboard — Trainer Progress Photos Tab
- [ ] AC-17: Trainee detail page has "Photos" tab (5th tab alongside Overview/Analytics/Nutrition/Activity)
- [ ] AC-18: Photos tab shows trainee's progress photos in grid layout
- [ ] AC-19: Category filter and date range filter on photos tab
- [ ] AC-20: Click photo opens detail dialog (read-only — no delete for trainer)
- [ ] AC-21: Comparison view accessible from trainer's photos tab
- [ ] AC-22: Empty state when trainee has no photos ("No progress photos yet")

### Pagination
- [ ] AC-23: Mobile gallery uses paginated API (20 per page) with infinite scroll
- [ ] AC-24: Web gallery uses paginated API with page navigation

## Edge Cases
1. What happens when trainee has 0 photos? → Empty state with CTA to take first photo
2. What happens when trainee has 200+ photos? → Pagination (20/page)
3. What happens when image upload fails mid-way? → Error toast, photo not added to gallery
4. What happens when trainer views trainee with no photos? → Empty state "No progress photos yet"
5. What happens when photo file exceeds 10MB? → Client-side validation error before upload
6. What happens when trainee deletes all photos then tries to compare? → "Need at least 2 photos" empty state
7. What happens when category filter returns 0 results? → "No photos in this category" empty state
8. What happens with network error during gallery load? → Error state with retry button
9. What happens when trainer navigates to trainee photos while impersonating? → Should work (read-only)
10. What happens when trainee_id in URL is invalid? → Error state, not crash

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Upload network failure | "Failed to upload photo. Please try again." toast | Rolls back optimistic update |
| Gallery load failure | Error card with retry button | Catches exception, shows error state |
| Delete failure | "Failed to delete photo" toast | Reverts deletion, photo reappears |
| Invalid file type | "Only JPEG, PNG, and WebP files are supported" | Client-side validation |
| File too large | "Photo must be under 10MB" | Client-side validation |
| Compare with <2 photos | "Take at least 2 progress photos to compare" | Shows empty state with CTA |
| Invalid trainee_id | Error state with back button | Catches 404/403 |

## UX Requirements
- **Loading state:** Skeleton grid matching photo tile layout
- **Empty state:** Illustration/icon + "Start tracking your transformation" + CTA button
- **Error state:** Error icon + message + retry button
- **Success feedback:** Toast on upload success, grid auto-refreshes
- **Mobile behavior:** Grid adapts to screen width (2 columns on phone, 3 on tablet)
- **Trainer view:** Read-only badge/indicator, no FAB, header shows trainee name

## Technical Approach

### Files to Modify (Mobile Bug Fixes):
- `mobile/lib/features/progress_photos/presentation/screens/photo_gallery_screen.dart` — Fix category tabs, add trainee_id support, pagination, trainer read-only mode
- `mobile/lib/features/progress_photos/presentation/screens/add_photo_screen.dart` — Fix category options (Other instead of duplicate Side)
- `mobile/lib/features/progress_photos/data/repositories/progress_photo_repository.dart` — Fix measurements JSON encoding, add trainee_id param, add pagination params
- `mobile/lib/features/progress_photos/presentation/providers/progress_photo_provider.dart` — Add trainee_id parameter support

### Files to Create (Web):
- `web/src/app/(trainee-dashboard)/trainee/progress-photos/page.tsx` — Trainee progress photos page
- `web/src/components/progress-photos/photo-grid.tsx` — Reusable photo grid component
- `web/src/components/progress-photos/photo-detail-dialog.tsx` — Full-size photo dialog
- `web/src/components/progress-photos/upload-dialog.tsx` — Photo upload dialog
- `web/src/components/progress-photos/comparison-view.tsx` — Side-by-side comparison
- `web/src/components/progress-photos/category-filter.tsx` — Category tab filter
- `web/src/components/trainees/trainee-photos-tab.tsx` — Trainer's trainee photos tab
- `web/src/hooks/use-progress-photos.ts` — React Query hooks for progress photos API
- `web/src/types/progress-photos.ts` — TypeScript types

### Files to Modify (Web):
- `web/src/app/(trainee-dashboard)/trainee/` sidebar/nav — Add Progress Photos link
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` — Add Photos tab
- `web/src/components/trainees/trainee-detail-tabs.tsx` or equivalent — Wire photos tab

### Backend:
- `backend/workouts/views.py` — Add pagination to ProgressPhotoViewSet (PageNumberPagination)
- Potentially add image size validation in serializer

## Out of Scope
- Video progress recordings (photos only)
- AI body composition analysis
- Social sharing of progress photos
- Automatic photo reminders/scheduling
- Photo annotation/markup
- Before/after collage generation
