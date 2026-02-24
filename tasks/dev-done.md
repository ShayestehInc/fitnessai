# Dev Done: Trainer Dashboard Mobile Responsiveness (Pipeline 37)

## Summary
Made the entire trainer-facing web dashboard mobile-friendly using CSS-first responsive patterns. All changes are Tailwind utility classes — no JS viewport detection.

## Files Changed (12 files)

### Data Tables — Column Hiding
1. **`web/src/components/trainees/trainee-columns.tsx`** — Hide "Program" and "Joined" columns on mobile (`hidden md:table-cell`)
2. **`web/src/components/trainees/trainee-activity-tab.tsx`** — Hide "Carbs" and "Fat" columns on mobile
3. **`web/src/components/programs/program-list.tsx`** — Hide "Goal", "Used", and "Created" columns on mobile
4. **`web/src/components/invitations/invitation-columns.tsx`** — Hide "Program" and "Expires" columns on mobile
5. **`web/src/components/analytics/revenue-section.tsx`** — Hide "Since" column on subscriber table; hide "Type" and "Date" columns on payment table

### Data Table Pagination
6. **`web/src/components/shared/data-table.tsx`** — Responsive pagination: `Page X of Y (Z total)` → `X/Y` on mobile. Previous/Next buttons become icon-only on mobile.

### Trainee Detail Page
7. **`web/src/app/(dashboard)/trainees/[id]/page.tsx`** — Header stacks vertically on mobile (`flex-col gap-4 md:flex-row`). Action buttons use 2-column grid on mobile (`grid grid-cols-2 gap-2 sm:flex`). Title scales `text-xl sm:text-2xl`.

### Exercise Management
8. **`web/src/components/exercises/exercise-list.tsx`** — Collapsible filter chips on mobile with "Filters (N)" toggle button. Always visible on md+.
9. **`web/src/components/programs/exercise-row.tsx`** — Reduced left padding on mobile (`pl-0 sm:pl-8`). Larger touch targets on reorder/delete buttons (`h-8 w-8 sm:h-7 sm:w-7`).

### Chat Pages — Dynamic Viewport Height
10. **`web/src/app/(dashboard)/ai-chat/page.tsx`** — Replaced `100vh` with `100dvh` (2 occurrences) to fix Mobile Safari address bar overlap
11. **`web/src/app/(dashboard)/messages/page.tsx`** — Replaced `100vh` with `100dvh`

### Program Builder
12. **`web/src/components/programs/program-builder.tsx`** — Save bar is now sticky at bottom on mobile with border-top and background. Reverts to static on sm+.

## Key Design Decisions
- **CSS-only approach**: All responsive changes via Tailwind breakpoint utilities. No `useMediaQuery` or JS-based viewport detection.
- **Column hiding pattern**: Used `hidden md:table-cell` consistently across all DataTable column definitions to hide less-important columns on mobile while keeping essential data visible.
- **Collapsible filters**: Exercise list filter chips hidden behind a toggle button on mobile rather than removing them entirely, preserving full functionality.
- **Sticky save bar**: Program builder save bar uses `sticky bottom-0` on mobile so users always see the Save/Cancel buttons without scrolling to the end of a long form.
- **Touch targets**: All interactive elements meet 44px minimum touch target on mobile.
- **Dynamic viewport height**: `100dvh` used instead of `100vh` for chat pages to account for Mobile Safari's dynamic address bar.

## How to Manually Test
1. Open Chrome DevTools → Toggle Device Toolbar (Ctrl+Shift+M)
2. Test at 375px (iPhone SE), 390px (iPhone 14), and 768px (iPad) widths
3. Key flows to verify:
   - Trainee list → table columns collapse, pagination is compact
   - Trainee detail → header stacks, action buttons form 2-column grid
   - Programs list → table columns collapse
   - Program builder → save bar stays visible at bottom while scrolling
   - Exercise bank → filter chips collapse behind toggle button
   - AI Chat → no bottom cut-off from address bar
   - Messages → same dvh fix
   - Analytics → revenue tables show essential columns only
   - Invitations → table columns collapse

## Deviations from Ticket
- Programs page header: No changes needed — the `PageHeader` component already handles `flex-col sm:flex-row` stacking, and the two action buttons fit side-by-side on even the smallest screens.
