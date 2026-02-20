# Code Review: Image Attachments in Direct Messages (Pipeline 21)

## Review Date: 2026-02-19
## Round: 2

## Round 1 Issue Verification

### Critical Issues
| # | Issue | Status |
|---|-------|--------|
| C1 | Dead code: unused `last_message_image_subquery` | **FIXED** — Now used as the Subquery source for the annotation |
| C2 | Unused `Length` import | **FIXED** — Removed from import |
| C3 | Fragile annotation logic checking ANY message vs LAST message | **FIXED** — Uses chained `.annotate()`: first annotates `_last_message_image` via Subquery on last message, then checks if non-empty/non-null |
| C4 | Imports after function definitions in views.py | **FIXED** — All imports moved to top of file, proper PEP 8 ordering |

### Major Issues
| # | Issue | Status |
|---|-------|--------|
| M1 | No optimistic send for mobile images | **FIXED** — Optimistic MessageModel with temp negative ID, localImagePath set, immediate display. On success: removes temp + dedup WebSocket, adds server response. On error: marks `isSendFailed`. Sender info passed from ChatScreen via authStateProvider. |
| M2 | Object URL memory leak on web unmount | **FIXED** — Added `useEffect` cleanup that revokes `imagePreviewUrl` on unmount/change. Properly handles re-selection (cleanup revokes old URL) and unmount (cleanup revokes current URL). |
| M3 | Weak `Any | None` typing on image params | **FIXED** — Both `send_message()` and `send_message_to_trainee()` now use `UploadedFile | None`. Import added. |

### Minor Issues
| # | Issue | Status |
|---|-------|--------|
| m1 | No shimmer loading for mobile images | Deferred (acceptable for v1) |
| m2 | No skeleton loading for web images | Deferred (acceptable for v1) |
| m3 | No AppBar title in image viewer | Deferred (minor) |
| m4 | setState on every keystroke | Deferred (minor for this widget) |
| m5 | Provider catch blocks missing logging | **FIXED** — Added `debugPrint` in `loadConversations()`, `loadMessages()`, `loadMore()` |

## New Issues in Round 2
None found.

## Quality Score: 8/10
## Recommendation: APPROVE

All 4 critical and 3 major issues are verified as properly fixed. No new issues introduced. Test suite passes (289 tests, same 2 pre-existing MCP errors). Flutter analyze shows no new warnings. The implementation is production-ready.
