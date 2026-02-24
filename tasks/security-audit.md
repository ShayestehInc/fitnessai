# Security Audit: Trainer Dashboard Mobile Responsiveness (Pipeline 37)

## Audit Date
2026-02-24

## Scope
Pipeline 37 — 12 web source files changed (all frontend, no backend). Changes consist of Tailwind CSS class modifications, minor JSX restructuring for responsive layouts, one new CSS utility class in `globals.css`, and one new `useState` boolean in `exercise-list.tsx`.

## Files Audited
1. `web/src/app/(dashboard)/ai-chat/page.tsx` — `100vh` to `100dvh` (2 occurrences)
2. `web/src/app/(dashboard)/messages/page.tsx` — `100vh` to `100dvh`
3. `web/src/app/(dashboard)/trainees/[id]/page.tsx` — Header stacking, action button grid, scrollable tabs
4. `web/src/app/globals.css` — New `.table-scroll-hint` CSS utility
5. `web/src/components/analytics/revenue-section.tsx` — Column hiding, header layout restructure
6. `web/src/components/exercises/exercise-list.tsx` — Collapsible filter toggle with `showFilters` state
7. `web/src/components/invitations/invitation-columns.tsx` — Column hiding
8. `web/src/components/programs/exercise-row.tsx` — Padding and touch target size adjustments
9. `web/src/components/programs/program-builder.tsx` — Sticky save bar on mobile
10. `web/src/components/programs/program-list.tsx` — Column hiding
11. `web/src/components/shared/data-table.tsx` — Responsive pagination text, scroll hint class, `className` prop on Column interface
12. `web/src/components/trainees/trainee-activity-tab.tsx` — Column hiding (Carbs, Fat)
13. `web/src/components/trainees/trainee-columns.tsx` — Column hiding (Program, Joined)

---

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (diff contains only CSS/layout changes)
- [x] All user input sanitized (no new user input handling added)
- [x] Authentication checked on all new endpoints (no new endpoints created)
- [x] Authorization — correct role/permission guards (no auth changes made)
- [x] No IDOR vulnerabilities (no data-fetching changes)
- [N/A] File uploads validated (no upload changes)
- [N/A] Rate limiting on sensitive endpoints (no endpoint changes)
- [x] Error messages don't leak internals (no error handling changes)
- [x] CORS policy appropriate (no CORS changes)

---

## Secrets Scan

Performed exhaustive grep across all changed files (source + task artifacts) for:
- API keys (`api_key`, `apikey`, `api-key`)
- Passwords and secrets (`password`, `secret`, `credential`)
- Tokens (`token`, `bearer`, `jwt`, `authorization`)
- Provider-specific prefixes (`sk-`, `pk_`, `AKIA`, `ghp_`, `gho_`, `AIza`, `xoxb`, `xoxp`)
- Key references (`private_key`, `access_key`, `OPENAI`, `STRIPE`, `AWS_`)
- Sensitive file types (`.env`, `.key`, `.pem`)
- Environment variable references (`process.env`, `NEXT_PUBLIC_`)

**Result: CLEAN.** Zero matches in any changed source file. No new configuration files introduced.

---

## Injection Vulnerabilities
| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| — | — | — | None found | — |

**Details:**
- Searched entire diff for `dangerouslySetInnerHTML`, `innerHTML`, `eval()`, `document.write`, `v-html`, `__html`. Zero matches.
- No new user input fields or `onChange` handlers introduced. All existing handlers in `exercise-row.tsx` remain untouched — only CSS class names on the containing elements changed.
- The new `showFilters` state toggle in `exercise-list.tsx` is a boolean controlling CSS visibility (`hidden`/`block`). It does not handle user text input and does not render user-controlled content.

---

## Auth & Authz Issues
| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| — | — | — | None found | — |

**Details:**
- **Zero backend files changed.** No changes to `backend/` directory.
- No API endpoints were added, removed, or modified.
- No new `fetch()`, `axios`, or API client calls introduced. The `ExportButton` URLs (`API_URLS.EXPORT_PAYMENTS`, `API_URLS.EXPORT_SUBSCRIBERS`) already existed; only their JSX layout positioning changed.
- No authentication middleware, route guards, or permission checks were altered.
- No new routes or navigation paths introduced.

---

## Data Exposure Assessment

- **No new API calls or data-fetching hooks added.**
- **No sensitive fields newly rendered or exposed.**
- **Column hiding is CSS-only (`hidden md:table-cell`).** Hidden columns remain in the DOM and HTML source. This is by design — the data was already authorized for and visible to the current user. CSS hiding is a UX optimization for screen space, not a security boundary. Server-side field filtering would be needed for actual data restriction (out of scope; the data shown is appropriate for the trainer role).
- **No `localStorage`, `sessionStorage`, or `cookie` access added.**
- **No environment variable references introduced.**

---

## CSS-Specific Security Analysis

1. **`globals.css` `.table-scroll-hint::after`** — Creates a gradient overlay using `var(--background)` and `var(--radius-md)`, both theme-defined CSS custom properties set in the same file. The `pointer-events: none` property correctly prevents the overlay from intercepting user clicks/touches. No CSS injection vector. No security impact.

2. **`className` on `Column<T>` interface** (`data-table.tsx` line 18) — The new optional `className?: string` property is consumed at lines 56 and 101 as `className={col.className}`. Every usage passes hardcoded string literals (e.g., `"hidden md:table-cell"`, `"hidden text-right md:table-cell"`). The `className` value is never derived from API responses, URL parameters, or user input. No injection risk.

3. **`sticky bottom-0 z-10`** on program builder save bar (`program-builder.tsx`) — The `z-index: 10` is moderate and does not create clickjacking concerns. The bar has solid `bg-background` background, preventing content beneath from being visible or clickable. Standard mobile sticky pattern.

4. **`100vh` to `100dvh` swap** in chat/messages pages — Pure CSS viewport unit change for Mobile Safari compatibility. No security impact.

---

## New Dependencies

**No new packages added.** No `package.json` or lock file changes. All changes use:
- Existing Tailwind CSS utility classes
- One new Lucide React icon (`Filter`) imported in `exercise-list.tsx` — already part of the existing `lucide-react` dependency
- Standard React `useState` hook (already imported)

---

## Informational Notes

| # | Severity | Description | Assessment |
|---|----------|-------------|------------|
| 1 | Info | Hidden table columns remain in DOM | CSS `display: none` via Tailwind `hidden` class removes columns visually but data persists in HTML source. This is intentional UX pattern. The data is authorized for the current user (trainer viewing their own trainees' data). No fix needed. |
| 2 | Info | `aria-hidden="true"` on mobile pagination text | The compact `{page}/{totalPages}` text for mobile uses `aria-hidden="true"` and the full `aria-label` on the parent paragraph ensures screen reader accessibility. Correctly implemented. |

---

## Fixes Applied
None required. No Critical, High, Medium, or Low security issues found.

---

## Summary

This is a **purely cosmetic/responsive-design changeset**. All 12 changed web source files contain exclusively:
- Tailwind CSS class modifications (responsive breakpoint prefixes like `sm:`, `md:`)
- CSS unit changes (`100vh` to `100dvh`)
- Layout adjustments (grid columns, gap sizes, padding, font sizes, touch target sizes)
- One new `useState<boolean>` for filter panel visibility toggle
- One new CSS utility class (`.table-scroll-hint`) for scroll affordance
- One new `className` property on the `Column<T>` interface (developer-defined, not user-controlled)

No authentication, authorization, data handling, API communication, or business logic was modified. No secrets, tokens, or sensitive data found anywhere in the diff. No new dependencies introduced. No backend or mobile code touched.

The initial assumption that this is a "CSS-only change with minimal security surface" is **confirmed and accurate**.

---

## Security Score: 10/10
## Recommendation: PASS

**Rationale:** Zero security findings of any severity. This changeset carries effectively zero security risk. It is entirely CSS and responsive layout work with no interaction with authentication, data persistence, or server communication. No secrets in code, no injection surfaces, no auth changes, no data exposure, no new dependencies.
