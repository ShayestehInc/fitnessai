# Feature: CSV Data Export for Trainer Dashboard

## Priority
High

## User Story
As a **trainer**, I want to **download CSV exports of my payment history, subscriber list, and trainee roster** so that I can **share data with my accountant, file taxes, and track my business performance in spreadsheets**.

## Background
Pipeline 28 added Trainer Revenue & Subscription Analytics with rich data tables (payments, subscribers). The entire platform currently has zero export/download functionality. Trainers can see their data but cannot extract it. CSV export is table-stakes for any business dashboard.

## Acceptance Criteria

### Backend — Export Service
- [ ] AC-1: New service file `backend/trainer/services/export_service.py` with three export functions
- [ ] AC-2: `export_payments_csv(trainer, days)` → returns CSV string with columns: Date, Trainee, Email, Type, Amount, Currency, Status, Description
- [ ] AC-3: `export_subscribers_csv(trainer)` → returns CSV string with columns: Trainee, Email, Amount (monthly), Currency, Status, Renewal Date, Days Until Renewal, Subscribed Since
- [ ] AC-4: `export_trainees_csv(trainer)` → returns CSV string with columns: Name, Email, Active, Profile Complete, Last Activity, Current Program, Joined
- [ ] AC-5: All export functions use `select_related('trainee')` or `select_related('profile')` — no N+1 queries
- [ ] AC-6: All export functions return frozen dataclasses wrapping the CSV content and metadata (filename, row_count)
- [ ] AC-7: Monetary amounts formatted as plain numbers (e.g., `29.99`), not currency strings — spreadsheet-friendly
- [ ] AC-8: Dates formatted as ISO 8601 (`YYYY-MM-DD` or `YYYY-MM-DD HH:MM:SS`) — spreadsheet-friendly
- [ ] AC-9: `export_payments_csv` respects `days` parameter (same clamping as revenue analytics: min=1, max=365, default=30)
- [ ] AC-10: Empty data returns CSV with header row only (no error)

### Backend — Export Views
- [ ] AC-11: `PaymentExportView` at `GET /api/trainer/export/payments/` with `?days=` query param
- [ ] AC-12: `SubscriberExportView` at `GET /api/trainer/export/subscribers/`
- [ ] AC-13: `TraineeExportView` at `GET /api/trainer/export/trainees/`
- [ ] AC-14: All three views require `[IsAuthenticated, IsTrainer]`
- [ ] AC-15: All three return `HttpResponse(content_type='text/csv')` with `Content-Disposition: attachment; filename="<name>_YYYY-MM-DD.csv"`
- [ ] AC-16: Filename includes export type and date: `payments_2026-02-21.csv`, `subscribers_2026-02-21.csv`, `trainees_2026-02-21.csv`
- [ ] AC-17: Row-level security — each export only includes the authenticated trainer's data

### Backend — URL Wiring
- [ ] AC-18: Three new URL patterns under `/api/trainer/export/` in `trainer/urls.py`
- [ ] AC-19: URL names: `export-payments`, `export-subscribers`, `export-trainees`

### Backend — Tests
- [ ] AC-20: Auth tests — unauthenticated returns 401, non-trainer returns 403 (for each endpoint)
- [ ] AC-21: Response tests — content type is `text/csv`, content-disposition header has correct filename
- [ ] AC-22: Content tests — CSV header row matches expected columns (for each endpoint)
- [ ] AC-23: Data tests — CSV rows contain correct data from fixtures (for each endpoint)
- [ ] AC-24: Row-level security tests — trainer A cannot see trainer B's data in any export
- [ ] AC-25: Empty data tests — returns header-only CSV, not an error (for each endpoint)
- [ ] AC-26: Payment period filter tests — `?days=30` and `?days=365` return different results
- [ ] AC-27: Payment status tests — all payment statuses appear in export (not filtered to succeeded-only)

### Frontend — ExportButton Component
- [ ] AC-28: Reusable `ExportButton` component at `web/src/components/shared/export-button.tsx`
- [ ] AC-29: Props: `url: string`, `filename: string`, `label?: string` (default "Export CSV")
- [ ] AC-30: Uses `Download` icon from lucide-react
- [ ] AC-31: On click: fetches URL with auth token, creates blob, triggers browser download with `filename`
- [ ] AC-32: Shows loading spinner during download (replaces icon with Loader2 spin animation)
- [ ] AC-33: Shows error toast on failure (uses existing toast system if available, otherwise console.error)
- [ ] AC-34: Disabled state while download is in progress (prevents double-click)
- [ ] AC-35: Uses `variant="outline"` and `size="sm"` — unobtrusive secondary action styling
- [ ] AC-36: Accessible: `aria-label` describes the action (e.g., "Export payments as CSV")

### Frontend — Integration Points
- [ ] AC-37: RevenueSection header gets two ExportButtons: "Export Payments" and "Export Subscribers"
- [ ] AC-38: Payment export button passes current period (`?days=` param) to match the active period selector
- [ ] AC-39: TraineesPage header gets one ExportButton: "Export Trainees"
- [ ] AC-40: Export buttons only render when data is loaded (not during loading/error/empty states)

### Frontend — Constants & Types
- [ ] AC-41: Three new URL constants in `constants.ts`: `EXPORT_PAYMENTS`, `EXPORT_SUBSCRIBERS`, `EXPORT_TRAINEES`

## Edge Cases
1. **No data at all** — Trainer with zero trainees/payments/subscribers downloads a CSV with just the header row. No error. File is still valid CSV.
2. **Special characters in names** — Trainee name contains commas, quotes, or unicode (e.g., `O'Brien, "DJ" Martinez`). CSV must properly escape these with RFC 4180 quoting.
3. **Null/missing fields** — `paid_at` is null, `current_period_end` is null, trainee has no profile. Export shows empty string, not "None" or "null".
4. **Very large dataset** — Trainer with 500+ trainees and 10,000+ payments. Export should stream efficiently. No pagination needed (all data in one file), but use Django's `StreamingHttpResponse` only if needed for memory — standard `HttpResponse` is fine for reasonable sizes.
5. **Concurrent downloads** — User clicks Export Payments then immediately clicks Export Subscribers. Both downloads should work independently.
6. **Network failure mid-download** — Frontend shows error toast, re-enables the button so user can retry.
7. **Payment days parameter invalid** — `?days=abc` or `?days=-5` falls back to default (30 days), matching existing `_parse_days_param` behavior.
8. **Trainee with no program** — Current Program column shows empty string.
9. **Canceled/paused subscriptions** — Subscriber export includes ALL subscriptions (active, paused, canceled) with their status column. Unlike MRR which only counts active, the export shows everything for bookkeeping.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Download fails (network) | Error toast: "Failed to download CSV. Please try again." | Button re-enables, icon returns to Download |
| Download fails (401) | Redirect to login | Auth token expired, normal auth flow |
| Download fails (403) | Error toast: "You don't have permission to export this data." | Non-trainer tried to access |
| Download in progress | Button disabled, spinner icon | Prevents duplicate requests |
| No data | Valid CSV downloads with header row only | Normal flow, file is 1 line |

## UX Requirements
- **Button placement — Revenue**: Export buttons appear in the Revenue section header, aligned right, next to the period selector. Small outline buttons with Download icon.
- **Button placement — Trainees**: Export button appears in the page header next to "Invite Trainee" button.
- **Loading state**: Download icon → spinning Loader2 while fetching. Button text stays the same.
- **Success feedback**: Browser's native download dialog handles this. No additional toast needed.
- **Error feedback**: Red error toast appears for 5 seconds.
- **Mobile behavior**: N/A — web dashboard only.

## Technical Approach

### Backend Files to Create
- `backend/trainer/services/export_service.py` — Three export functions, each returning a frozen dataclass with `content: str`, `filename: str`, `row_count: int`
- `backend/trainer/export_views.py` — Three views: PaymentExportView, SubscriberExportView, TraineeExportView (separate file to keep views.py from growing further)
- `backend/trainer/tests/test_export.py` — Comprehensive export tests

### Backend Files to Modify
- `backend/trainer/urls.py` — Add three new URL patterns under `export/` prefix

### Frontend Files to Create
- `web/src/components/shared/export-button.tsx` — Reusable ExportButton component

### Frontend Files to Modify
- `web/src/lib/constants.ts` — Add EXPORT_PAYMENTS, EXPORT_SUBSCRIBERS, EXPORT_TRAINEES URL constants
- `web/src/components/analytics/revenue-section.tsx` — Add export buttons to header
- `web/src/app/(dashboard)/trainees/page.tsx` — Add export button to header

### Key Design Decisions
1. **Separate `export_views.py`** — Trainer views.py is already 1000+ lines. New file keeps it manageable.
2. **Service returns dataclass** — Follows project convention (never return raw dicts). Dataclass wraps CSV content + metadata.
3. **Python `csv` module with `io.StringIO`** — Standard library, no dependencies. Write to StringIO buffer, return as string.
4. **`HttpResponse` not `StreamingHttpResponse`** — For reasonable trainer datasets (< 10K rows), standard response is simpler and sufficient.
5. **Frontend blob download** — `fetch()` with auth headers → `response.blob()` → `URL.createObjectURL()` → click hidden `<a>` → `URL.revokeObjectURL()`. This is the standard pattern for authenticated file downloads in SPAs.
6. **All statuses included in payment/subscriber exports** — Unlike the analytics views which filter to succeeded/active only, exports include everything for complete bookkeeping records.

## Out of Scope
- Ambassador export (future pipeline)
- Admin-level bulk export
- PDF reports or formatted reports
- Mobile export
- Email delivery of reports
- Excel (.xlsx) format
- Custom column selection
- Date range picker (uses same period selector as revenue analytics)
- Scheduled/automated exports
