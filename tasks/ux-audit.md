# UX Audit: Progress Photos

## Issues Found & Fixed

### 1. Missing focus-visible rings on category filter buttons (Accessibility — High)
**File:** `web/src/components/progress-photos/category-filter.tsx`
**Issue:** Radio buttons in the category filter had no visible focus indicator for keyboard users. WCAG 2.4.7 requires visible focus indicators.
**Fix:** Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` classes.

### 2. Missing focus-visible rings on upload dialog category radio buttons (Accessibility — High)
**File:** `web/src/components/progress-photos/upload-dialog.tsx`
**Issue:** Category selector buttons (Front/Side/Back/Other) in the upload form had no keyboard focus indicator.
**Fix:** Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring` classes.

### 3. No drag-and-drop support on file upload area (Usability — Medium)
**File:** `web/src/components/progress-photos/upload-dialog.tsx`
**Issue:** The upload drop zone only supported click-to-select. Users expect drag-and-drop for file uploads — this is standard in modern web apps (Stripe, Linear, etc.).
**Fix:** Added `onDrop`, `onDragOver`, `onDragLeave` handlers with visual feedback (border color change, text change to "Drop photo here"). Extracted file validation into shared `processFile` callback to avoid duplication.

### 4. Generic empty state when category filter returns 0 results (UX Copy — Medium)
**File:** `web/src/components/progress-photos/photo-grid.tsx`
**Issue:** When a user selects "Front" filter and has no front photos, they saw "No progress photos yet" with "Start tracking your transformation..." — misleading because they may have photos in other categories. The "Take First Photo" CTA was also shown incorrectly.
**Fix:** When a category filter is active (`category !== "all"`), show `No {category} photos` with description `No photos found in the "{category}" category. Try selecting a different category or upload a new photo.` CTA button only shows when on "All" tab.

### 5. Delete confirmation has no cancel escape (Usability — Medium)
**File:** `web/src/components/progress-photos/photo-detail-dialog.tsx`
**Issue:** When user clicks "Delete Photo", it changes to "Confirm Delete" but there was no explicit cancel button. The only way to cancel was to close the entire dialog, losing context.
**Fix:** Added a "Cancel" button next to "Yes, Delete" in the confirmation state. Both buttons are `flex-1` for equal sizing. Cancel resets `confirmingDelete` to false.

### 6. Missing focus-visible rings on comparison view select elements (Accessibility — Medium)
**File:** `web/src/components/progress-photos/comparison-view.tsx`
**Issue:** The "Before" and "After" photo selector dropdowns had no visible focus ring for keyboard users.
**Fix:** Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring` to both select elements.

### 7. Comparison view placeholder not accessible to screen readers (Accessibility — Low)
**File:** `web/src/components/progress-photos/comparison-view.tsx`
**Issue:** The dashed-border placeholder area between photo selectors and the actual comparison was purely visual with no screen reader context.
**Fix:** Added `role="status"`, `aria-label`, `aria-hidden="true"` on decorative elements, and a `sr-only` span with instructions.

### 8. Measurement diffs not announced to screen readers (Accessibility — Low)
**File:** `web/src/components/progress-photos/comparison-view.tsx`
**Issue:** When measurement diffs appear after selecting two photos, screen readers wouldn't announce the new content.
**Fix:** Added `aria-live="polite"` to the measurement changes container.

### 9. Mobile category filter missing "Other" tab (Consistency — Medium)
**File:** `mobile/lib/features/progress_photos/presentation/widgets/category_filter_bar.dart`
**Issue:** Web category filter shows All/Front/Side/Back/Other, but mobile only showed All/Front/Side/Back. Photos uploaded with "Other" category would be invisible unless "All" was selected — confusing and inconsistent.
**Fix:** Added `CategoryTab(label: 'Other', value: 'other')` to `defaultCategories`.

### 10. Mobile photo detail dialog missing semantic label (Accessibility — Medium)
**File:** `mobile/lib/features/progress_photos/presentation/widgets/photo_detail_dialog.dart`
**Issue:** The dialog had no Semantics widget, so screen readers (TalkBack/VoiceOver) couldn't announce what the dialog contained.
**Fix:** Wrapped the dialog's Column child in a `Semantics` widget with a descriptive label including category and date.

## Issues Found & Not Fixed (need design decisions)

### 1. Measurement diff color coding assumes "decrease = good" (UX — Low)
**File:** `web/src/components/progress-photos/comparison-view.tsx`
**Issue:** Green for decrease, amber for increase. But for arms/chest, increase is often the goal. Fixing this properly would require knowing the user's fitness goal (bulking vs cutting).
**Recommendation:** Consider making the color neutral (both amber/gray) or adding a user preference. Not changed because it's a reasonable default for the majority of measurements (waist, hips, thighs).

### 2. No photo crop/rotate before upload (UX Enhancement)
Users may want to adjust photos before uploading. Would require a third-party image editor component (e.g., react-image-crop). Not in scope for this ticket.

### 3. No bulk delete or multi-select on web grid (UX Enhancement)
Users with many photos have no way to select and delete multiple photos at once. Would need a selection mode UI pattern. Consider for a future iteration.

## States Checklist
- [x] Loading — Skeleton grid on web, CircularProgressIndicator on mobile
- [x] Empty (no photos at all) — Illustration + descriptive copy + CTA
- [x] Empty (filtered, no results) — Category-specific message (FIXED)
- [x] Error — Error card with retry button (web), error icon with retry (mobile)
- [x] Success — Toast on upload/delete, auto-refresh via query invalidation
- [x] Disabled — Compare button disabled when < 2 photos
- [x] Read-only (trainer view) — No delete, no upload, no FAB, descriptive empty state

## Overall UX Score: 8/10

The Progress Photos feature has solid fundamentals: proper loading/empty/error states, good responsive grid layout, clean comparison view with measurement diffs, and a well-structured upload form. The main gaps were accessibility-related (missing focus indicators for keyboard users, screen reader context) and a few polish items (no drag-and-drop, ambiguous empty state when filtering, no cancel for delete confirmation). All have been fixed. The remaining suggestions are enhancements that would elevate from good to great but are not blockers.
