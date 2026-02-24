# Security Audit: Admin Dashboard Mobile Responsiveness (Pipeline 38)

## Audit Date
2026-02-24

## Scope
Pipeline 38 -- 22 web source files changed (all frontend `web/src/`, no backend). Changes consist exclusively of Tailwind CSS class modifications for mobile responsiveness on admin dashboard pages. No JavaScript logic, no API calls, no backend files modified.

## Files Audited
1. `web/src/app/(admin-dashboard)/admin/coupons/page.tsx` -- Search input width responsive
2. `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx` -- Search input width responsive
3. `web/src/app/(admin-dashboard)/admin/tiers/page.tsx` -- Dialog scroll overflow
4. `web/src/app/(admin-dashboard)/admin/trainers/page.tsx` -- Search input width, button touch targets
5. `web/src/app/(admin-dashboard)/admin/users/page.tsx` -- Search input width responsive
6. `web/src/app/(admin-dashboard)/layout.tsx` -- `100vh` to `100dvh`
7. `web/src/components/admin/ambassador-detail-dialog.tsx` -- Dialog scroll overflow
8. `web/src/components/admin/ambassador-list.tsx` -- Flex wrap metadata, button touch targets
9. `web/src/components/admin/coupon-detail-dialog.tsx` -- Dialog scroll overflow, column hiding
10. `web/src/components/admin/coupon-form-dialog.tsx` -- Dialog scroll overflow, responsive grid
11. `web/src/components/admin/coupon-list.tsx` -- Column hiding (Applies To, Valid Until)
12. `web/src/components/admin/create-ambassador-dialog.tsx` -- Dialog scroll overflow
13. `web/src/components/admin/create-user-dialog.tsx` -- Dialog scroll overflow, responsive button layout
14. `web/src/components/admin/past-due-full-list.tsx` -- Flex wrap metadata
15. `web/src/components/admin/subscription-detail-dialog.tsx` -- Dialog scroll overflow, scrollable tabs
16. `web/src/components/admin/subscription-history-tabs.tsx` -- Column hiding (Description, By, Reason)
17. `web/src/components/admin/subscription-list.tsx` -- Column hiding (Next Payment, Past Due)
18. `web/src/components/admin/tier-form-dialog.tsx` -- Dialog scroll overflow, responsive grid
19. `web/src/components/admin/tier-list.tsx` -- Column hiding (Trainee Limit, Order), responsive actions
20. `web/src/components/admin/trainer-detail-dialog.tsx` -- Dialog scroll overflow, responsive button layout
21. `web/src/components/admin/trainer-list.tsx` -- Column hiding (Trainees, Joined)
22. `web/src/components/admin/upcoming-payments-list.tsx` -- Flex wrap metadata
23. `web/src/components/admin/user-list.tsx` -- Column hiding (Trainees, Created)

---

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (diff contains only CSS/layout changes)
- [x] All user input sanitized (no new user input handling added)
- [x] Authentication checked on all new endpoints (no new endpoints created)
- [x] Authorization -- correct role/permission guards (no auth changes made)
- [x] No IDOR vulnerabilities (no data-fetching changes)
- [N/A] File uploads validated (no upload changes)
- [N/A] Rate limiting on sensitive endpoints (no endpoint changes)
- [x] Error messages don't leak internals (no error handling changes)
- [x] CORS policy appropriate (no CORS changes)

---

## Secrets Scan

Performed grep across all changed files (source + task artifacts) for:
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
| -- | -- | -- | None found | -- |

**Details:**
- Searched entire diff for `dangerouslySetInnerHTML`, `innerHTML`, `eval()`, `document.write`, `v-html`, `__html`. Zero matches.
- No new user input fields or `onChange` handlers introduced. All existing `onChange` handlers (e.g., search inputs in `coupons/page.tsx`, `trainers/page.tsx`) remain functionally identical -- only `className` attributes were changed.
- No new dynamic content rendering. All added strings are hardcoded Tailwind class names.

---

## Auth & Authz Issues
| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

**Details:**
- **Zero backend files changed.** No changes to `backend/` directory.
- No API endpoints were added, removed, or modified.
- No new `fetch()`, `axios`, or API client calls introduced.
- No authentication middleware, route guards, or permission checks were altered.
- No new routes or navigation paths introduced.
- The admin dashboard layout (`layout.tsx`) change is purely a CSS viewport unit swap (`h-screen` to `h-dvh`). The authentication guard and role check in that layout file remain untouched.

---

## Data Exposure Assessment: Column Hiding

This is the most relevant security consideration for this pipeline. Multiple table columns were given `className: "hidden md:table-cell"` to hide them on smaller screens.

**Columns hidden on mobile:**
- Coupon list: "Applies To", "Valid Until"
- Coupon detail (usage table): "Used At"
- Subscription list: "Next Payment", "Past Due"
- Subscription history (payment tab): "Description"
- Subscription history (changes tab): "By", "Reason"
- Tier list: "Trainee Limit", "Order"
- Trainer list: "Trainees", "Joined"
- User list: "Trainees", "Created"

**Assessment: No security risk.**

1. **Data remains in DOM.** The Tailwind `hidden` class applies `display: none`. The `md:table-cell` class restores `display: table-cell` at the `md` breakpoint (768px+). The `<TableCell>` and `<TableHead>` elements containing the data are still rendered to the DOM. This was verified by reading the `DataTable` component at `/Users/rezashayesteh/Desktop/shayestehinc/fitnessai/web/src/components/shared/data-table.tsx` (lines 73-76 for headers, lines 118-122 for cells). The `className` is passed directly to the `<TableHead>` and `<TableCell>` elements. No conditional rendering (`{condition && ...}` or ternary) is involved.

2. **No API response filtering.** The server still returns the full data payload. The hiding is purely visual. There is no change to what data the client requests or receives.

3. **Authorized data.** All hidden columns contain data the admin user is already authorized to see. These are admin dashboard pages accessible only to the ADMIN role. Hiding "Joined date" or "Trainee count" on mobile is a UX convenience, not a security boundary.

4. **Consistent with existing pattern.** This is the same `hidden md:table-cell` pattern already established in Pipeline 37 for the trainer dashboard tables.

---

## CSS-Specific Security Analysis

1. **`max-h-[90dvh] overflow-y-auto` on DialogContent** (10 dialog components) -- Constrains dialog height to 90% of dynamic viewport and enables scrolling. Standard responsive pattern. The `overflow-y-auto` does not expose hidden content that was previously inaccessible; it makes already-rendered content scrollable. No security impact.

2. **`w-full sm:max-w-sm` on search inputs** (5 pages) -- Changes input width from `max-w-sm` to full width on mobile, constrained at `sm` breakpoint. No change to input handling, validation, or submission. No security impact.

3. **`min-h-[44px] sm:min-h-0` on buttons** (trainers page filter buttons, ambassador list button) -- Increases touch target size on mobile to meet WCAG 2.5.8 target size guidelines. Purely visual. No security impact.

4. **`flex-wrap` and `gap-x-N gap-y-N`** (past-due list, upcoming payments, ambassador list) -- Allows metadata items to wrap to new lines on narrow screens. No data changes. No security impact.

5. **`flex-col sm:flex-row`** (create-user-dialog delete buttons, trainer-detail-dialog suspend buttons, tier-list action buttons) -- Stacks buttons vertically on mobile. No change to button handlers or functionality. No security impact.

6. **`grid-cols-1 sm:grid-cols-2` / `grid-cols-1 sm:grid-cols-3`** (coupon-form-dialog, tier-form-dialog) -- Responsive form grids. No change to form fields, validation, or submission. No security impact.

7. **`overflow-x-auto` wrapper on TabsList** (subscription-detail-dialog) -- Enables horizontal scrolling for tabs on narrow screens. No new tabs or content introduced. No security impact.

8. **`h-dvh` replacing `h-screen`** (admin layout) -- Dynamic viewport height for Mobile Safari compatibility. No security impact.

---

## New Dependencies

**No new packages added.** No `package.json` or lock file changes. All changes use existing Tailwind CSS utility classes and existing React component library (`@/components/ui/*`).

---

## Informational Notes

| # | Severity | Description | Assessment |
|---|----------|-------------|------------|
| 1 | Info | 14 table columns hidden on mobile via CSS | CSS `display: none` via Tailwind `hidden` class. Data remains in DOM and HTML source. Authorized for the admin user. No server-side data filtering change. Not a security concern. |
| 2 | Info | Dialog heights constrained to 90dvh | Standard overflow handling for small screens. Existing content scrollable, no new content exposed. |

---

## Fixes Applied
None required. No Critical, High, Medium, or Low security issues found.

---

## Summary

This is a **purely cosmetic/responsive-design changeset** targeting the admin dashboard. All 22 changed web source files contain exclusively:
- Tailwind CSS class modifications (responsive breakpoint prefixes: `sm:`, `md:`)
- CSS unit changes (`h-screen` to `h-dvh`)
- Dialog overflow handling (`max-h-[90dvh] overflow-y-auto`)
- Table column hiding via `hidden md:table-cell` on the Column `className` property
- Touch target size increases (`min-h-[44px]`)
- Layout adjustments (responsive grids, flex-wrap, flex-col)
- Tab list horizontal scroll wrapper

No authentication, authorization, data handling, API communication, or business logic was modified. No secrets, tokens, or sensitive data found anywhere in the diff. No new dependencies introduced. No backend or mobile code touched. No `dangerouslySetInnerHTML`, `eval`, `innerHTML`, or any other XSS vector introduced. No new event handlers, form submissions, or API calls.

The CSS column hiding pattern (`hidden md:table-cell`) is confirmed safe: data remains in the DOM, the server response is unchanged, and all data is authorized for the admin role. This is a UX optimization, not a security boundary.

---

## Security Score: 10/10
## Recommendation: PASS

**Rationale:** Zero security findings of any severity. This changeset carries effectively zero security risk. It is entirely CSS and responsive layout work with no interaction with authentication, data persistence, or server communication. No secrets in code, no injection surfaces, no auth changes, no data exposure, no new dependencies. The column hiding via CSS is confirmed to be DOM-level visual hiding only, with no impact on data authorization or API responses.
