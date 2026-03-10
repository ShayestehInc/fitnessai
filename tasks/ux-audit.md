# UX Audit: Progression Engine (v6.5 Step 7)

## Scope

This feature is **backend-only** — no mobile/frontend UI was built (session runner UI is Step 8). The UX audit covers API response design and developer experience.

## API Response UX

| #   | Severity | Endpoint                  | Issue                                                                 | Status |
| --- | -------- | ------------------------- | --------------------------------------------------------------------- | ------ |
| 1   | Info     | All progression endpoints | Responses include human-readable `reason_display` field               | GOOD   |
| 2   | Info     | next-prescription         | Returns `confidence` level (high/medium/low) for UI to show certainty | GOOD   |
| 3   | Info     | progression-readiness     | Returns structured `blockers` array for UI to show specific issues    | GOOD   |
| 4   | Info     | apply-progression         | Returns 201 with full event details including old/new prescription    | GOOD   |

## Missing States

- [x] Loading / skeleton — N/A (backend only)
- [x] Empty / zero data — hold prescription with reason codes
- [x] Error / failure — DRF validation errors returned
- [x] Success / confirmation — 201 with event details
- [x] Permission denied — 403 for trainees on apply-progression

## Overall UX Score: 9/10

No UI to audit. API design is clean with good human-readable messages for future UI consumption.
