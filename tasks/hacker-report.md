# Hacker Report: Progress Photos

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Low | Web `use-progress-photos.ts` | `useComparePhotos` hook | Used by comparison view | Exported but never imported anywhere. Dead code. ComparisonView does client-side diff instead of using the backend `/compare/` endpoint. |
| 2 | Low | Backend `compare` endpoint | `GET /progress-photos/compare/` | Used by web/mobile | Web does client-side comparison only; mobile uses its own provider. Backend endpoint is functional but under-utilized from web. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | Web `PhotoDetailDialog` | When `photo_url` is null, dialog shows no image area at all. The `p-0` on DialogContent + the `p-6` details section creates an awkward top-heavy layout with no visual anchor. | Consider showing a placeholder icon in the image area even when URL is null (same pattern used in ComparisonView). |
| 2 | Low | Mobile `PhotoDetailDialog` | Dialog has no max-height constraint. On a phone with many measurements and long notes, the dialog column can overflow the screen since it uses `MainAxisSize.min` without a scroll wrapper. | Wrap the Column in a SingleChildScrollView or ConstrainedBox with max height. |
| 3 | Low | Mobile `_DateGroup` / `PhotoDetailDialog` | Dates are shown as raw `YYYY-MM-DD` strings (e.g., "2026-03-01") instead of human-readable format like "March 1, 2026". The web version formats dates properly with `toLocaleDateString`. | Format the date string using `DateFormat` from the intl package (already imported in add_photo_screen). |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Mobile: Comparison screen ignores trainee_id | 1. As trainer, open a trainee's photo gallery. 2. Tap Compare icon in app bar. 3. Gallery navigates to `/progress-photos/compare?trainee_id=X`. | ComparisonScreen fetches that trainee's photos using the trainee_id query param. | **FIXED.** ComparisonScreen called `ref.watch(photosProvider)` without the family argument (trainee_id was never passed). The screen didn't accept or parse `trainee_id` at all. Updated ComparisonScreen to accept a `traineeId` parameter and updated the router to extract it from query params. |
| 2 | Medium | Web: ComparisonView stale selection state | 1. Open Compare dialog. 2. Select "Before" and "After" photos. 3. Close dialog. 4. Reopen Compare dialog. | Selections should be reset to a fresh start. | **FIXED.** `photo1Id` and `photo2Id` state persisted across dialog open/close cycles. Added `handleOpenChange` that resets both to `null` when the dialog closes. |
| 3 | Low | Web: Upload dialog memory leak | 1. Open upload dialog. 2. Select a photo (creates Object URL for preview). 3. Close dialog without submitting. 4. Repeat many times. | Object URLs should be cleaned up on unmount. | **FIXED.** Added `useEffect` cleanup that revokes the preview Object URL on component unmount. |
| 4 | Medium | Web: Compare only works within current page | 1. Have 25+ photos across multiple pages. 2. Open Compare dialog on page 1. | Can compare any two photos from your full library. | Only photos on the current page (max 20) are available for comparison. Pagination makes cross-page comparison impossible. |
| 5 | Low | Mobile: Repository returns raw dicts | All methods in `progress_photo_repository.dart` return `Map<String, dynamic>`. | Return typed result classes per project conventions. | Returns `Map<String, dynamic>` with `'success'` boolean keys. Violates project rule: "return dataclass or pydantic models, never return dict." Not fixed here as it requires a broader refactor with custom result types. |
| 6 | Medium | Backend: Silent date validation failures | 1. Call API with `date_from=not-a-date`. | Return 400 error explaining invalid date format. | Invalid dates are silently ignored (`pass` in the `except ValueError` blocks at views.py lines 1890 and 1898). Returns unfiltered results instead of an error, which violates the project rule against error silencing. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Web ComparisonView | Fetch ALL photos (unpaginated) for comparison mode, or add a dedicated "compare" page that loads all photos instead of using the paginated current-page subset. | Current pagination limit of 20 makes cross-page comparison impossible. Users wanting to compare their first photo (page 3) with their latest (page 1) cannot do so. |
| 2 | Medium | Web PhotoDetailDialog | Add a "Download" button to save the full-resolution photo locally. | Users may want to share their progress photos outside the app. Currently the only way is right-click > save image. |
| 3 | Medium | Web/Mobile | Display the photo count per category on the filter tabs (e.g., "Front (4)", "Back (2)"). | Helps users quickly understand their photo distribution and find gaps in coverage. |
| 4 | Low | Web UploadDialog | Add a character counter showing "X/500" below the notes textarea. | The textarea has `maxLength={500}` but no visual feedback about remaining characters. |
| 5 | Medium | Mobile PhotoDetailDialog | Add a "Share" button using the platform share sheet. | Progress photos are inherently social -- users want to share transformations. Currently no way to share directly from the detail view. |
| 6 | Low | Web/Mobile Measurements | Allow user preference for unit system (cm vs inches). | Currently hardcoded to "cm" everywhere. Users in the US may prefer inches. |
| 7 | Medium | Mobile ComparisonScreen | Show the category badge in the photo picker bottom sheet. | When selecting photos to compare, users see only the date, not which category (front/side/back) each photo is. Makes it hard to select matching views for apples-to-apples comparison. |

## Summary
- Dead UI elements found: 1 (unused `useComparePhotos` hook)
- Visual bugs found: 3
- Logic bugs found: 6
- Improvements suggested: 7
- Items fixed by hacker: 3

## Chaos Score: 6/10

The Progress Photos feature is functional at its core but had a critical bug where the mobile comparison screen completely ignored the `trainee_id` parameter (now fixed). The web side is more polished but had stale state issues in the comparison dialog (now fixed) and has a design limitation where pagination prevents cross-page photo comparison. The mobile repository layer violates project conventions by returning raw dicts instead of typed models. No security issues found -- the backend properly enforces row-level access control and validates file types/sizes.
