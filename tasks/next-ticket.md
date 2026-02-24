# Feature: Admin Dashboard Mobile Responsiveness

## Priority
High

## User Story
As a platform **admin** accessing the dashboard from a phone or tablet, I want all admin pages to be usable and visually polished on mobile so that I can manage trainers, subscriptions, tiers, coupons, users, and ambassadors on the go without needing a desktop.

## Acceptance Criteria
- [ ] AC1: Trainer list table hides "Trainees" and "Joined" columns on mobile (`hidden md:table-cell`)
- [ ] AC2: Subscription list table hides "Next Payment" and "Past Due" columns on mobile
- [ ] AC3: Coupon list table hides "Applies To" and "Valid Until" columns on mobile
- [ ] AC4: User list table hides "Trainees" and "Created" columns on mobile
- [ ] AC5: Tier list table hides "Trainee Limit" and "Order" columns on mobile
- [ ] AC6: Tier list action buttons (Edit/Delete) stack vertically on mobile (`flex flex-col sm:flex-row`)
- [ ] AC7: All admin dialogs have `max-h-[90dvh] overflow-y-auto` for mobile viewport safety
- [ ] AC8: Subscription detail dialog tabs and action forms are usable at 375px width
- [ ] AC9: All page-level filter inputs use `w-full sm:max-w-sm` instead of bare `max-w-sm`
- [ ] AC10: Ambassador list metadata wraps properly on mobile (no horizontal overflow)
- [ ] AC11: Trainer detail dialog suspend/activate confirmation buttons stack on mobile
- [ ] AC12: All admin page headers use responsive stacking (already handled by PageHeader component — verify)
- [ ] AC13: Past due and upcoming payment cards are fully readable at 375px
- [ ] AC14: Touch targets >= 44px on all mobile interactive elements (buttons, toggles, links)
- [ ] AC15: No horizontal body scroll on any admin page at 320-1920px viewport widths

## Edge Cases
1. Admin with 0 trainers, 0 subscriptions — empty states render correctly on mobile
2. Trainer name 200+ characters — truncates with ellipsis, title tooltip
3. Coupon code with 50 characters — truncates in table cell
4. Subscription detail dialog with 50+ payment history rows — scrollable within dialog
5. 10+ tier entries in the tier table — no layout break
6. Ambassador with $99,999.99 earnings — number doesn't overflow card
7. Past due alerts with 30+ day severity — red color coding visible on mobile
8. Multiple filter dropdowns active simultaneously on subscriptions page
9. 320px viewport (iPhone SE) — all tables show essential columns without body overflow
10. Landscape orientation on phone — layouts still usable

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| API error on any list | ErrorState with "Failed to load..." | Shows retry button |
| Empty list after filter | EmptyState with clear message | No broken layout |
| Dialog action fails | Toast error notification | Preserves dialog state |

## UX Requirements
- **Loading state:** Already handled by skeleton components — verify they render at mobile widths
- **Empty state:** Already handled by EmptyState component — verify responsive
- **Error state:** Already handled by ErrorState component — verify responsive
- **Success feedback:** Toast notifications via sonner — no changes needed
- **Mobile behavior:** Tables hide less-important columns, dialogs fill mobile viewport, buttons stack vertically, filter controls go full-width

## Technical Approach
### Files to modify:

**Table column hiding (5 files):**
1. `web/src/components/admin/trainer-list.tsx` — Add `className: "hidden md:table-cell"` to Trainees and Joined columns
2. `web/src/components/admin/subscription-list.tsx` — Add to Next Payment and Past Due columns
3. `web/src/components/admin/coupon-list.tsx` — Add to Applies To and Valid Until columns
4. `web/src/components/admin/user-list.tsx` — Add to Trainees and Created columns
5. `web/src/components/admin/tier-list.tsx` — Add to Trainee Limit and Order columns; stack action buttons

**Dialog overflow fixes (check all admin dialogs):**
6. `web/src/components/admin/subscription-detail-dialog.tsx` — Verify max-h + overflow
7. `web/src/components/admin/coupon-detail-dialog.tsx` — Verify max-h + overflow
8. `web/src/components/admin/coupon-form-dialog.tsx` — Add max-h + overflow if missing
9. `web/src/components/admin/trainer-detail-dialog.tsx` — Stack confirm buttons; add overflow
10. `web/src/components/admin/tier-form-dialog.tsx` — Add max-h + overflow if missing
11. `web/src/components/admin/create-user-dialog.tsx` — Add max-h + overflow if missing
12. `web/src/components/admin/create-ambassador-dialog.tsx` — Add max-h + overflow if missing

**Filter input fixes (4 pages):**
13. `web/src/app/(admin-dashboard)/admin/trainers/page.tsx` — `w-full sm:max-w-sm` on search input
14. `web/src/app/(admin-dashboard)/admin/subscriptions/page.tsx` — Same pattern
15. `web/src/app/(admin-dashboard)/admin/coupons/page.tsx` — Same pattern
16. `web/src/app/(admin-dashboard)/admin/users/page.tsx` — Same pattern

**Ambassador list mobile fix:**
17. `web/src/components/admin/ambassador-list.tsx` — Wrap metadata responsively

**Layout dvh fix:**
18. `web/src/app/(admin-dashboard)/layout.tsx` — Replace `h-screen` with `h-dvh` if applicable

### CSS-first approach:
All changes via Tailwind utility classes. No JavaScript viewport detection. Consistent `md:` breakpoint (768px) for mobile/desktop transitions, matching Pipelines 36/37 patterns.

## Out of Scope
- Converting tables to card views on mobile (too complex for this pipeline)
- Redesigning admin pages or flows
- Backend changes
- Mobile app changes
