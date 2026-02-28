# UX Audit: Calendar Integration Completion (Pipeline 41)

## Audit Date: 2026-02-27
## Pipeline: 41
## Auditor: UX Auditor
## Scope: 14 calendar feature files audited across screens, widgets, providers, and models

---

## Summary

The calendar integration feature is well-structured with clean visual hierarchy, proper platform-adaptive widgets, and comprehensive CRUD feedback. However, I found 8 usability issues and 8 accessibility issues. All have been fixed in this pass. The most impactful fixes were replacing raw `CircularProgressIndicator` with shimmer loading placeholders (matching the app's established pattern), adding accessibility semantics throughout, and improving the no-connection empty state copy.

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Major | CalendarEventsScreen | Loading state used raw `CircularProgressIndicator` instead of shimmer placeholders. Ticket explicitly requires shimmer. Inconsistent with app patterns (`trainer_notifications_screen` uses `LoadingShimmer`). | Replaced with `LoadingShimmer`-based skeleton matching the event list layout (date header shimmer + event row shimmers with time column and content). | **FIXED** |
| 2 | Major | TrainerAvailabilityScreen | Loading state used raw `CircularProgressIndicator` instead of shimmer placeholders. Same inconsistency as #1. | Replaced with `LoadingShimmer`-based skeleton matching the day-grouped slot layout (day name shimmers + slot row shimmers). | **FIXED** |
| 3 | Major | CalendarProviderFilter | Filter chips used `GestureDetector` which provides zero visual feedback on tap (no ripple, no highlight). Users get no confirmation their tap registered. | Replaced with `InkWell` wrapped in `Material` for proper ripple effect. Added `Semantics` with `button: true` and `selected` state. | **FIXED** |
| 4 | Medium | CalendarNoConnectionView | Copy said "Connect a calendar first" which is terse and commanding. No explanation of what connecting does. Button label "Go to Calendar Settings" with a back arrow icon was confusing -- it looked like a back button but was the primary CTA. | Improved copy: title "No calendar connected", subtitle "Connect your Google or Microsoft calendar to see your events here." Changed button to "Connect a Calendar" with link icon. Added horizontal padding. | **FIXED** |
| 5 | Medium | AvailabilitySlotEditor | Bottom sheet had no drag handle, making it unclear to users that the sheet can be swiped down to dismiss. This is a standard mobile UX pattern present in most production apps. | Added a centered 32x4 drag handle bar at the top of the bottom sheet with 0.2 opacity. | **FIXED** |
| 6 | Minor | CalendarConnectionScreen | Loading state used raw `CircularProgressIndicator` instead of `AdaptiveSpinner`. Other screens (`trainer_dashboard`, `settings`) use `AdaptiveSpinner` for platform-adaptive loading. | Replaced with `AdaptiveSpinner()` for iOS/Android consistency. | **FIXED** |
| 7 | Minor | AvailabilitySlotTile | No discoverability hint that slots can be swiped to delete. Users unfamiliar with the pattern may never discover this affordance. | Added "Swipe left to delete" to the Semantics label. Partial fix -- a visual hint on first use would be ideal but requires more infrastructure. | **FIXED (partial)** |
| 8 | Minor | AvailabilitySlotEditor | `DropdownButtonFormField` used deprecated `value` parameter, generating lint warnings. | Changed to `initialValue` parameter. | **FIXED** |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | A (1.1.1) | CalendarEventTile: No semantic labels. Screen readers cannot convey event title, time, or location meaningfully. | Added `Semantics` wrapper with combined label: "{title}, {time range}, at {location}". | **FIXED** |
| 2 | A (1.1.1) | _ProviderBadge: Single-letter badge ("G"/"M") with no tooltip or semantic label. Screen readers and long-press users cannot identify the provider. | Added `Tooltip` with "Google Calendar" / "Microsoft Outlook" and `Semantics` label. | **FIXED** |
| 3 | A (4.1.2) | AvailabilitySlotTile: No semantic labels. Screen readers cannot convey time range or active status. Edit button had no tooltip. | Added `Semantics` with time range and active status. Added `tooltip: 'Edit time slot'` to edit `IconButton`. | **FIXED** |
| 4 | A (4.1.2) | CalendarProviderFilter chips: No semantic roles or selected state communicated to assistive technology. | Added `Semantics(button: true, selected: ...)` with "Filter by {label}" semantic label. | **FIXED** |
| 5 | A (1.1.1) | Empty state icons (events + availability screens): Missing `semanticLabel`. Messages not grouped for screen readers. | Added `semanticLabel` to icons. Wrapped empty states in `Semantics` with combined descriptive label. | **FIXED** |
| 6 | AA (2.4.4) | Back buttons across all 3 screens lacked tooltips. Custom `IconButton` leading widgets need explicit tooltips for screen readers. | Added descriptive tooltips: "Back to Calendar Settings" on events/availability, "Go back" on connection screen. | **FIXED** |
| 7 | A (1.1.1) | CalendarNoConnectionView: Calendar icon had no semantic label. | Added `semanticLabel: 'Calendar not connected'`. | **FIXED** |
| 8 | A (4.1.2) | FloatingActionButton on availability screen: No tooltip. Screen readers would announce as unlabeled button. | Added `tooltip: 'Add availability slot'`. | **FIXED** |

---

## Missing States Checklist

- [x] **Loading / skeleton** -- Events and availability screens now use shimmer placeholders that match their content layout. Connection screen uses AdaptiveSpinner.
- [x] **Empty / zero data** -- Events screen has "No upcoming events" with pull-to-sync hint. Availability screen has "No availability set" with FAB hint. No-connection state has explanatory copy with action button.
- [x] **Error / failure** -- All screens use `ref.listen` to surface errors via `showAdaptiveToast`. Error messages from the provider layer include context (e.g., "Failed to load events", "Sync failed").
- [x] **Success / confirmation** -- Create, update, delete, connect, disconnect, and sync operations all show success toasts. Delete uses confirmation dialog with `isDestructive: true`.
- [ ] **Offline / degraded** -- Not handled. No offline detection or stale-data indicator. Events screen preserves last loaded data on error, but no visual cue that data may be stale. Not critical for this pipeline.
- [x] **Permission denied** -- CalendarNoConnectionView handles the "no connection" case. Auth errors bubble through the error toast system.

---

## Copy Review

| Screen | Element | Copy | Assessment |
|--------|---------|------|------------|
| Events | AppBar title | "Calendar Events" | Clear and descriptive |
| Events | Empty title | "No upcoming events" | Good |
| Events | Empty subtitle | "Pull down to sync your calendar" | Actionable hint |
| Events | Date headers | "Today" / "Monday, Mar 2" | Contextual, highlights today |
| Availability | AppBar title | "Availability" | Clear |
| Availability | Empty title | "No availability set" | Good |
| Availability | Empty subtitle | "Tap + to add your first time slot" | References the FAB |
| Availability | Delete dialog | "Remove this availability slot?" | Clear, non-alarming wording |
| Availability | Validation | "End time must be after start time" | Specific and helpful |
| Availability | Editor title | "Add Availability" / "Edit Availability" | Context-aware |
| Connection | Header title | "Connect Your Calendar" | Welcoming |
| Connection | Header subtitle | "Sync your Google or Microsoft calendar..." | Explains value proposition |
| No Connection | Title | "No calendar connected" | States fact clearly |
| No Connection | Subtitle | "Connect your Google or Microsoft calendar to see your events here." | Explains what to do and why |
| No Connection | Button | "Connect a Calendar" | Clear CTA |

---

## Consistency with App Patterns

| Pattern | Expected | Calendar Feature | Status |
|---------|----------|-----------------|--------|
| Toast messages | `showAdaptiveToast` with `ToastType` | Used correctly throughout | Consistent |
| Confirm dialogs | `showAdaptiveConfirmDialog` with `isDestructive` | Used for delete and disconnect | Consistent |
| Loading spinner | `AdaptiveSpinner` for simple loading | Now used on connection screen | **FIXED** |
| Shimmer loading | `LoadingShimmer` for list/content loading | Now used on events and availability | **FIXED** |
| Card styling | `theme.cardColor` + rounded borders + divider | Consistent across all tiles and cards | Consistent |
| Platform-adaptive | `Switch.adaptive`, `CupertinoDatePicker` on iOS | Used correctly in slot tile and editor | Consistent |
| Bottom sheet | Rounded top corners + `isScrollControlled` | Used correctly, now with drag handle | Consistent |
| Error handling | Toast-based, no silent failures | All provider errors surface to UI | Consistent |
| `const` constructors | Required throughout | Used correctly | Consistent |
| Max 150 lines per widget | Convention from CLAUDE.md | All widgets under limit | Consistent |

---

## Items Not Fixed (Require Design Decisions or Larger Changes)

| # | Impact | Area | Observation | Suggested Approach |
|---|--------|------|-------------|-------------------|
| 1 | Medium | Events screen | No offline/stale data indicator. When events are loaded from cache after a failed sync, there is no visual cue. | Add a subtle "Last synced: X minutes ago" chip below the filter bar. Requires design input on placement and styling. |
| 2 | Low | Availability screen | Swipe-to-delete has no visual discoverability hint for sighted users. | Consider a brief onboarding tooltip on first visit, or a subtle peek animation on the first slot. Requires design discussion. |
| 3 | Low | Events screen | Tapping an event tile does nothing. Per ticket this is out of scope (external link deferred), but a non-interactive tile can be confusing. | Consider adding `InkWell` with external link icon to indicate tappability once the feature is built. |
| 4 | Low | Events screen | Filter state resets to "All" when navigating away and returning. | Persist last-used filter in provider state so it survives navigation. |

---

## Overall UX Score: 8/10

**Rationale:** The calendar integration is well-built with clean visual design, proper platform-adaptive patterns, comprehensive state handling, and consistent use of the app's shared widget library. All CRUD flows provide immediate feedback. The optimistic toggle on availability slots prevents flicker. Grouping by date (events) and day-of-week (availability) is intuitive.

The score of 8 reflects the post-fix quality. Pre-fix score would have been 6/10 due to the missing shimmer loading states (major inconsistency with app patterns), zero accessibility semantics across all widgets, and non-responsive filter chips. All issues found have been addressed.

**Files modified in this audit:**
- `mobile/lib/features/calendar/presentation/screens/calendar_events_screen.dart` -- shimmer loading, back button tooltip, empty state semantics
- `mobile/lib/features/calendar/presentation/screens/trainer_availability_screen.dart` -- shimmer loading, back button tooltip, FAB tooltip, empty state semantics
- `mobile/lib/features/calendar/presentation/screens/calendar_connection_screen.dart` -- AdaptiveSpinner, back button tooltip
- `mobile/lib/features/calendar/presentation/widgets/calendar_event_tile.dart` -- Semantics wrapper, provider badge tooltip
- `mobile/lib/features/calendar/presentation/widgets/availability_slot_tile.dart` -- Semantics wrapper, edit button tooltip
- `mobile/lib/features/calendar/presentation/widgets/availability_slot_editor.dart` -- drag handle, deprecated parameter fix
- `mobile/lib/features/calendar/presentation/widgets/calendar_provider_filter.dart` -- InkWell + Semantics
- `mobile/lib/features/calendar/presentation/widgets/calendar_no_connection_view.dart` -- improved copy, icon semantic label, back button tooltip
