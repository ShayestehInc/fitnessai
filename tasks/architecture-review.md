# Architecture Review: Progress Photos

## Review Date: 2026-03-09

## Files Reviewed
- `backend/workouts/models.py` (ProgressPhoto model)
- `backend/workouts/serializers.py` (ProgressPhotoSerializer)
- `backend/workouts/views.py` (ProgressPhotoViewSet, ProgressPhotoPagination)
- `backend/workouts/tests/test_progress_photos.py`
- `web/src/hooks/use-progress-photos.ts`
- `web/src/types/progress.ts`
- `web/src/lib/constants.ts` (API_URLS additions)
- `web/src/components/progress-photos/` (all 5 components)
- `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `mobile/lib/features/progress_photos/presentation/providers/progress_photo_provider.dart`
- `mobile/lib/features/progress_photos/data/repositories/progress_photo_repository.dart`

## Architectural Alignment
- [x] Follows existing layered architecture (ViewSet -> Serializer -> Model)
- [x] Models/schemas in correct locations (ProgressPhoto in workouts app)
- [x] No business logic in routers/views (validation in serializer, filtering in queryset)
- [x] Web follows established React Query + hook pattern consistent with other features
- [x] Mobile follows Riverpod provider pattern consistent with other features
- [x] API constants centralized in `web/src/lib/constants.ts`
- [x] TypeScript types defined in dedicated file

### Issues Found & Fixed

| # | Severity | File | Issue | Fix Applied |
|---|----------|------|-------|-------------|
| 1 | Major | `views.py` ProgressPhotoViewSet | **Missing ADMIN role in `get_queryset()`** -- Admin users fell through to `ProgressPhoto.objects.none()`, unlike every other ViewSet in the file which handles `is_admin()` | Added `elif user.is_admin()` branch with optional `trainee_id` filter and full `select_related` |
| 2 | Major | `views.py` ProgressPhotoViewSet | **Orphaned files on delete** -- `destroy()` deleted the DB record but left the image file on disk/storage. Other ViewSets in this file (e.g., Exercise) use `default_storage.delete()` for cleanup | Added `perform_destroy()` that deletes the storage file before removing the DB record |
| 3 | Minor | `views.py` compare endpoint | **Two separate DB queries** for photo1 and photo2 (`queryset.get(id=X)` twice) -- unnecessary round-trip | Consolidated into single `queryset.filter(id__in=[...])` with len check |
| 4 | Minor | `serializers.py` | **`import json` inside method body** (in `validate_measurements`) -- inconsistent with project convention of top-level imports | Moved `import json` to module top-level |

### Items Noted but Not Fixed (acceptable)

| # | Item | Rationale |
|---|------|-----------|
| 1 | Silent date filter failures (invalid `date_from`/`date_to` silently ignored) | This is a query filter, not a create/update. Silently ignoring invalid optional filter params is a reasonable API design choice -- returning unfiltered results is safer than erroring. |
| 2 | Mobile repository returns `Map<String, dynamic>` instead of typed result objects | This is the established pattern across ALL mobile repositories (habits, payments, calendar, etc.). Changing it here would be inconsistent. Addressing this is a cross-cutting refactor, not scoped to this feature. |
| 3 | Web ComparisonView does client-side photo lookup instead of using the `/compare/` endpoint | Acceptable because the photos are already loaded in the grid. Using the API compare endpoint would add an unnecessary round-trip. The endpoint is still available for mobile and future use. |

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes -- ProgressPhoto model pre-existed |
| Migrations reversible | N/A | No new migrations |
| Indexes added for new queries | PASS | Existing indexes on `(trainee, date)` and `(trainee, category)` correctly cover the new filter queries |
| No N+1 query patterns | PASS | `select_related('trainee')` used on all queryset paths |

## Scalability Concerns
| # | Area | Status | Notes |
|---|------|--------|-------|
| 1 | Pagination | PASS | 20 items/page with max 50. Pagination class properly configured. |
| 2 | Unbounded fetches | PASS | All list endpoints paginated. Trainer "all trainees photos" query is bounded by pagination. |
| 3 | File storage | PASS | `upload_to='progress_photos/%Y/%m/'` distributes files by month, avoiding single-directory bloat |
| 4 | Query efficiency | PASS | Compare endpoint now uses single query. Indexes cover filter patterns. |
| 5 | Image serving | NOTE | Photos served through Django (via `photo_url` using `request.build_absolute_uri`). For production scale, should use a CDN/S3 presigned URLs. Not blocking -- standard for the current project state. |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | No image resizing/thumbnails -- full images served for grid view | Low | Add thumbnail generation (e.g., django-imagekit) in a future iteration. Not blocking for MVP. |
| 2 | Web comparison view loads ALL photos into memory for picker | Low | At scale (200+ photos), the dropdown will be unwieldy. Consider a paginated search picker in a future iteration. |

## Technical Debt Reduced
- Added proper pagination where none existed before
- Added file cleanup on delete (was missing even in the original model)
- Added admin role support, closing a role-coverage gap

## Architecture Score: 8/10

The implementation is architecturally sound. It follows existing patterns across all three layers (backend, web, mobile). The data model was already in place and well-indexed. The new code adds pagination, proper role-based access, filtering, and a compare endpoint -- all following REST conventions. The four issues found and fixed (admin role, orphaned files, duplicate queries, inline import) were real but straightforward. No fundamental design problems.

## Recommendation: APPROVE
