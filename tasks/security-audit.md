# Security Audit: v6.5 Navigation Wiring

## Audit Date

2026-03-10

## Scope

Navigation-only changes across 3 commits (`HEAD~3..HEAD`). No backend changes, no new API calls, no data handling logic.

## Files Audited

- `mobile/lib/features/home/presentation/widgets/v65_feature_cards.dart` (new)
- `mobile/lib/features/home/presentation/widgets/dashboard_content.dart`
- `mobile/lib/features/exercises/presentation/screens/exercise_bank_screen.dart`
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart`
- `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart`
- `mobile/lib/core/router/app_router.dart` (14 new route registrations)
- `mobile/ios/Podfile.lock` (dependency additions: file_picker, DKImagePickerController, SDWebImage, SwiftyGif)

## Checklist

- [x] No secrets, API keys, passwords, or tokens in changed files
- [x] No secrets in new `v65_feature_cards.dart`
- [x] All new routes behind global auth redirect (`app_router.dart:1647-1667`)
- [x] No new API endpoints or calls introduced
- [x] No user input collected or persisted
- [x] Route path parameters use `int.parse()` (consistent with existing pattern)
- [x] Query param `name` is URI-encoded with `Uri.encodeComponent()` in all new navigation calls
- [x] CORS/CSRF not applicable (client-side navigation only)
- [x] No file uploads introduced in these changes

## Secrets Scan

Grepped all changed files for: `api_key`, `password`, `secret`, `token`, `bearer`, `credential`, hardcoded URLs with keys. **Zero matches in new/changed code.** The one match in `community_ws_service.dart` is pre-existing and retrieves a stored JWT at runtime -- not a hardcoded secret.

## Injection Vulnerabilities

| #   | Type | File:Line | Issue      | Fix |
| --- | ---- | --------- | ---------- | --- |
| --  | --   | --        | None found | --  |

All route path parameters (`:exerciseId`, `:traineeId`, `:planId`, etc.) are parsed with `int.parse()`, preventing path traversal or injection via route segments. Query parameters (`name`) are display-only strings passed to widget constructors -- no SQL, no shell, no HTML rendering.

## Auth & Authz Issues

| #   | Severity | Endpoint | Issue      | Fix |
| --- | -------- | -------- | ---------- | --- |
| --  | --       | --       | None found | --  |

The router's global `redirect` function (`app_router.dart:1647`) checks `authStateProvider` on every navigation. If `user == null`, all routes except `/login`, `/register`, `/forgot-password`, and `/reset-password` redirect to `/login`. All 14 new routes are standard `GoRoute` entries without per-route redirect overrides, so they inherit this auth guard.

Note: Role-based authorization (e.g., trainer-only routes like `/trainer/correlations`) is not enforced at the router level -- it relies on backend API permission checks when data is fetched. This is the existing pattern throughout the app and is not a regression.

## Data Exposure

No sensitive data in route URLs. The only user-facing data passed in navigation is:

- Exercise IDs (integers)
- Trainee IDs (integers)
- Exercise/trainee display names (URI-encoded, display-only)

No PII, no tokens, no email addresses in route parameters.

## Low-Severity Observations (Pre-existing, Not Regressions)

| #   | Severity | File:Line                         | Issue                                                                    | Notes                                                                                                                                                                   |
| --- | -------- | --------------------------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| L1  | Low      | `trainee_detail_screen.dart:688`  | `displayName` not URI-encoded in calendar route query param              | Pre-existing code, not part of this diff. Names with `&` or `=` could break query parsing.                                                                              |
| L2  | Low      | `trainee_detail_screen.dart:1728` | `displayName` not URI-encoded in messages route query param              | Pre-existing code, not part of this diff. Same issue as L1.                                                                                                             |
| L3  | Low      | `app_router.dart` (throughout)    | `int.parse()` on path params throws `FormatException` on malformed input | Pre-existing pattern across all routes. Only reachable via `context.push()` with known-good IDs from the app -- not user-editable URL bars. Low risk in mobile context. |

## New Dependencies (Podfile.lock)

| Package     | Version | Risk                                                                                             |
| ----------- | ------- | ------------------------------------------------------------------------------------------------ |
| file_picker | 0.0.1   | Pulls in DKImagePickerController (photo gallery access). No known CVEs. Standard Flutter plugin. |
| SDWebImage  | 5.21.5  | Widely used iOS image loading library. No known CVEs at this version.                            |
| SwiftyGif   | 5.4.5   | GIF rendering. No known CVEs.                                                                    |

## Security Score: 9/10

No issues introduced by these changes. The -1 is for the pre-existing unencoded `displayName` usages (L1, L2) which are worth fixing in a future pass but are not part of this diff.

## Recommendation: PASS

This is a clean navigation wiring change. All new routes are behind auth, all dynamic parameters are properly typed or URI-encoded, and no secrets or sensitive data are exposed. No Critical or High issues found -- no fixes required.
