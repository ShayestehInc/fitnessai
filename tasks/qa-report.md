# QA Report: CSV Data Export for Trainer Dashboard

## Test Results
- Total: 39 (new) + 514 (existing, excl. 2 pre-existing mcp_server import errors)
- Passed: 39 new + 514 existing = 553 total
- Failed: 0 (our changes)
- Skipped: 0
- Pre-existing errors: 2 (mcp_server ModuleNotFoundError — unrelated to this feature)

## Failed Tests
None.

## Acceptance Criteria Verification

### Backend — Export Service
- [x] AC-1: New service file `export_service.py` with three functions — PASS
- [x] AC-2: `export_payments_csv` with correct columns — PASS (tests: `test_csv_header_row`, `test_payment_appears_in_csv`)
- [x] AC-3: `export_subscribers_csv` with correct columns — PASS (tests: `test_csv_header_row`, `test_subscriber_appears_in_csv`)
- [x] AC-4: `export_trainees_csv` with correct columns — PASS (tests: `test_csv_header_row`, `test_trainee_appears_in_csv`)
- [x] AC-5: `select_related` used, no N+1 — PASS (annotate + Prefetch used for trainees, select_related for payments/subscribers)
- [x] AC-6: Frozen `CsvExportResult` dataclass — PASS (verified in code)
- [x] AC-7: Amounts as plain numbers with 2 decimals — PASS (`_format_amount` uses `f"{amount:.2f}"`)
- [x] AC-8: Dates as ISO 8601 — PASS (`_format_date` and `_format_date_only`)
- [x] AC-9: Days parameter with clamping — PASS (tests: `test_days_30_filters_recent`, `test_days_365_includes_old`, `test_invalid_days_defaults_to_30`)
- [x] AC-10: Empty data returns header-only CSV — PASS (tests: 3x `test_empty_data_returns_header_only`)

### Backend — Export Views
- [x] AC-11: PaymentExportView at correct path — PASS
- [x] AC-12: SubscriberExportView at correct path — PASS
- [x] AC-13: TraineeExportView at correct path — PASS
- [x] AC-14: `[IsAuthenticated, IsTrainer]` — PASS (tests: 3x auth tests)
- [x] AC-15: HttpResponse with text/csv and Content-Disposition — PASS (tests: `test_content_type_is_csv`, `test_content_disposition_has_filename`)
- [x] AC-16: Filename includes type and date — PASS
- [x] AC-17: Row-level security — PASS (tests: 3x isolation tests)

### Backend — URL Wiring
- [x] AC-18: Three URL patterns under `export/` — PASS
- [x] AC-19: URL names: `export-payments`, `export-subscribers`, `export-trainees` — PASS

### Backend — Tests
- [x] AC-20: Auth tests for all endpoints — PASS (6 tests)
- [x] AC-21: Response format tests — PASS (6 tests)
- [x] AC-22: CSV header row tests — PASS (3 tests)
- [x] AC-23: Data correctness tests — PASS (3+ tests)
- [x] AC-24: Row-level security tests — PASS (3 tests)
- [x] AC-25: Empty data tests — PASS (3 tests)
- [x] AC-26: Period filter tests — PASS (`test_days_30_filters_recent`, `test_days_365_includes_old`)
- [x] AC-27: All payment statuses appear — PASS (`test_all_payment_statuses_appear`)

### Frontend — ExportButton Component
- [x] AC-28: Component at `shared/export-button.tsx` — PASS
- [x] AC-29: Correct props (url, filename, label, aria-label) — PASS
- [x] AC-30: Download icon from lucide-react — PASS
- [x] AC-31: Blob download with auth token — PASS (includes token refresh)
- [x] AC-32: Loading spinner during download — PASS (Loader2 with animate-spin)
- [x] AC-33: Error toast on failure — PASS (Sonner toast)
- [x] AC-34: Disabled state during download — PASS
- [x] AC-35: `variant="outline"` and `size="sm"` — PASS
- [x] AC-36: `aria-label` on button — PASS

### Frontend — Integration Points
- [x] AC-37: Two ExportButtons in RevenueSection header — PASS
- [x] AC-38: Payment export passes `?days=` param — PASS
- [x] AC-39: Export button in TraineesPage header — PASS
- [x] AC-40: Buttons only render when data is loaded — PASS (conditional on `hasData` / `data.results.length > 0`)

### Frontend — Constants & Types
- [x] AC-41: Three URL constants added — PASS

## Bugs Found Outside Tests
None.

## Edge Cases Verified
1. No data → header-only CSV — PASS (3 tests)
2. Special characters in names → properly escaped — PASS (`test_comma_in_name_is_escaped`)
3. Commas in description → properly quoted — PASS (`test_description_with_commas`)
4. Null paid_at → falls back to created_at — PASS (`test_null_paid_at_uses_created_at`)
5. Null period_end → empty string in CSV — PASS (`test_null_period_end_shows_empty`)
6. All payment statuses included — PASS (`test_all_payment_statuses_appear`)
7. All subscription statuses included — PASS (`test_all_subscription_statuses_appear`)
8. Invalid days param → defaults to 30 — PASS (`test_invalid_days_defaults_to_30`)
9. Trainer isolation on all endpoints — PASS (3 isolation tests)

## Confidence Level: HIGH
All 41 acceptance criteria verified PASS. All 9 edge cases handled. 39 new tests pass. 514 existing tests pass. TypeScript compiles clean. No bugs found.
