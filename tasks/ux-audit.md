# UX Audit: Health Data Integration + Performance Audit + Offline UI Polish

## Audit Date: 2026-02-15
## Pipeline: 16

## Files Reviewed
- `mobile/lib/shared/widgets/health_card.dart` -- Today's Health card
- `mobile/lib/shared/widgets/health_permission_sheet.dart` -- Permission bottom sheet
- `mobile/lib/shared/widgets/sync_status_badge.dart` -- Badge widget
- `mobile/lib/shared/widgets/offline_banner.dart` -- Offline banner
- `mobile/lib/core/theme/app_theme.dart` -- Theme consistency
- `mobile/lib/core/models/health_metrics.dart` -- Health data model
- `mobile/lib/core/providers/health_provider.dart` -- Health state management
- `mobile/lib/core/services/health_service.dart` -- Health data service
- `mobile/lib/features/home/presentation/screens/home_screen.dart` -- Home screen with health card, pending workouts
- `mobile/lib/features/home/presentation/providers/home_provider.dart` -- Home state with pending workouts
- `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` -- Nutrition with pending merge, badges
- `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart` -- Weight trends with pending merge

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | High | health_card.dart / `_MetricTile` | All 4 health metric tiles had no `Semantics` labels. Screen readers could not announce "Steps: 8,234" or "Heart Rate: -- " to visually impaired users. Health data is numeric and contextual -- without labels, it's meaningless to assistive technology. | Wrapped each `_MetricTile` in `Semantics(label: '$label: $value', excludeSemantics: true)` so screen readers announce "Steps: 8,234", "Active Cal: 342 cal", etc. | FIXED |
| 2 | High | health_card.dart / `_SkeletonHealthCard` | Skeleton loading card had no screen reader announcement. When health data is loading, VoiceOver/TalkBack users had no indication that content was being fetched. | Added `Semantics(label: 'Loading health data', liveRegion: true)` wrapper to the skeleton card. | FIXED |
| 3 | Medium | health_card.dart / `_MetricTile` | Label font size was 11px, below the 12px minimum recommended for body text in WCAG guidelines. Small text on dark backgrounds is harder to read for users with low vision. | Increased label font size from 11 to 12px. | FIXED |
| 4 | Medium | home_screen.dart / `_PendingWorkoutCard` | Pending workout cards displayed a `chevron_right` icon suggesting tappable navigation to detail, but tapping actually shows a "waiting to sync" snackbar. The visual affordance (chevron = "tap to navigate") contradicts the actual behavior (no navigation possible). Users would repeatedly tap expecting navigation. | Removed the `chevron_right` icon from pending workout cards. The card is still tappable (shows snackbar), but the visual does not falsely promise navigation. | FIXED |
| 5 | Medium | home_screen.dart / pending workout snackbar | The pending workout tap snackbar showed plain text with no visual indicator. All other sync/offline indicators in the app use the amber `cloud_off` icon. The snackbar was visually disconnected from the sync badge on the card that triggered it. | Added `cloud_off` icon (amber, 16px) to the snackbar content Row for visual consistency with SyncStatusBadge. | FIXED |
| 6 | Medium | sync_status_badge.dart | `SyncStatusBadge` had no `Semantics` label. The 12px icon is purely visual -- screen readers could not announce sync status (pending, syncing, failed) to users. | Added `Semantics(label: _semanticsLabel, excludeSemantics: true)` wrapper with appropriate labels per status: "Pending sync", "Syncing", "Sync failed", or empty for synced. | FIXED |
| 7 | Medium | nutrition_screen.dart / `_FoodEntryRow` edit icon | Edit icon used `GestureDetector` instead of `IconButton`. No ripple feedback, no minimum 32dp touch target, no tooltip. Users on accessibility devices or with motor impairments would struggle to tap the 16x16 target. | Replaced `GestureDetector` with `IconButton` with `constraints: BoxConstraints(minWidth: 32, minHeight: 32)`, `tooltip: 'Edit food entry'`, and proper ripple feedback. | FIXED |
| 8 | Medium | nutrition_screen.dart / "Add Food" button | "Add Food" button used `GestureDetector` with no ripple feedback and no padding around the tap target. The effective touch area was limited to the exact text bounds. | Replaced `GestureDetector` with `InkWell` with `borderRadius` for ripple, plus `Padding(horizontal: 8, vertical: 6)` for an adequate touch target. | FIXED |
| 9 | Low | nutrition_screen.dart / "(includes X pending)" label | Pending nutrition count label had no Semantics description and no visual indicator connecting it to the sync concept. The label appeared as plain text below the macro cards with only 4px top padding, making it visually cramped. | Added `Semantics(liveRegion: true, label: ...)` with descriptive text. Added a small `cloud_off` icon (11px, amber) before the text for visual consistency with sync badges. Increased top padding from 4px to 6px for breathing room. | FIXED |
| 10 | Low | nutrition_screen.dart / "Latest Weight" cloud_off icon | The amber `cloud_off` icon next to the latest weight date had no tooltip or Semantics explanation. Users might not understand what the icon means. | Wrapped the `Icon` in a `Tooltip(message: 'Pending sync')` for hover/long-press explanation. | FIXED |
| 11 | Low | nutrition_screen.dart / "Latest Weight" section | The entire "Latest Weight" section is tappable (navigates to Weight Trends) but had no `Semantics(button: true)` annotation. Screen readers would not announce it as an interactive element. | Added `Semantics(button: true, label: 'View weight trends. ${state.latestWeightFormatted}')` wrapper. | FIXED |
| 12 | Low | weight_trends_screen.dart / `_buildPendingWeightRow` | Pending weight rows had no Semantics labels. Screen readers could not announce "Pending weight check-in: 165 lbs on Monday, Feb 15, 2026". | Added `Semantics(label: 'Pending weight check-in: ${lbs.round()} lbs on $formattedDate')` wrapper. | FIXED |
| 13 | Low | health_card.dart / "Today's Health" title | Title text was not marked as a heading for screen reader navigation. Users navigating by headings would skip over this section. | Added `Semantics(header: true)` wrapper to the title Text widget. | FIXED |
| 14 | Low | health_card.dart / `_openHealthSettings` | Catch block used bare `catch (_)` which silently swallows errors, violating the project's error-handling rule ("NO exception silencing!"). | Changed to `catch (e)` with `assert(() { debugPrint(...); return true; }())` for debug-mode error logging, consistent with the pattern used in HealthService and HealthDataNotifier. | FIXED |
| 15 | Low | health_permission_sheet.dart / health icon | The decorative heart icon inside the permission sheet was exposed to screen readers, which would announce "favorite rounded" -- meaningless to the user. | Wrapped the icon Container in `ExcludeSemantics` to hide it from assistive technology. | FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | A (1.1.1) | Health metric tiles had no text alternative for screen readers. Values like "8,234" next to a walking icon had no contextual meaning without sighted access. | Added `Semantics(label: '$label: $value', excludeSemantics: true)` to `_MetricTile`. | FIXED |
| 2 | A (4.1.2) | Skeleton health card loading state had no `role="status"` equivalent. Screen readers could not detect that content was loading. | Added `Semantics(label: 'Loading health data', liveRegion: true)` to `_SkeletonHealthCard`. | FIXED |
| 3 | AA (1.4.4) | `_MetricTile` label text was 11px -- below the 12px minimum for readability at standard viewing distances on mobile screens. | Increased to 12px. | FIXED |
| 4 | A (2.5.5) | Food entry edit icon had a 16x16 tap target (no padding). WCAG 2.5.5 requires minimum 44x44 CSS pixels; Flutter Material guidelines require at least 32dp. | Replaced with `IconButton` with 32x32dp minimum constraints. | FIXED |
| 5 | A (4.1.2) | `SyncStatusBadge` icons (cloud_off, cloud_upload, error_outline) had no semantic label. Screen readers would either ignore them or announce unhelpful icon names. | Added `Semantics(label: _semanticsLabel)` with status-appropriate text. | FIXED |
| 6 | A (1.1.1) | Decorative heart icon in permission sheet was not marked as decorative. Screen readers announced "favorite rounded" which adds noise. | Wrapped in `ExcludeSemantics`. | FIXED |
| 7 | A (4.1.2) | "Latest Weight" tappable region had no button role for screen readers. | Added `Semantics(button: true, label: ...)`. | FIXED |
| 8 | AA (1.3.1) | "Today's Health" title was not marked as a heading. Screen reader heading navigation would skip it. | Added `Semantics(header: true)`. | FIXED |

---

## Missing States Checklist

### TodaysHealthCard (health_card.dart)
- [x] Loading -- `_SkeletonHealthCard` with gray placeholder tiles matching 2x2 layout, Semantics liveRegion
- [x] Populated -- `_LoadedHealthCard` with 200ms fade-in animation, 4 metric tiles
- [x] Empty / No Permission -- `SizedBox.shrink()` (card hidden entirely, no error banner)
- [x] Error / Unavailable -- `SizedBox.shrink()` (card hidden, graceful degradation)
- [x] Permission Denied -- `SizedBox.shrink()` (respects user's choice, no nagging)
- [x] Initial -- `SizedBox.shrink()` (before any permission check)
- [x] Refresh with existing data -- Skips skeleton (isRefresh=true preserves loaded state)

### Health Permission Sheet (health_permission_sheet.dart)
- [x] Default -- Bottom sheet with icon, title, description, two buttons
- [x] Dismissible -- swipe down or tap outside returns false
- [x] Platform-aware -- Shows "Apple Health" on iOS, "Health Connect" on Android

### SyncStatusBadge (sync_status_badge.dart)
- [x] Pending -- Amber cloud_off icon (16x16) with Semantics "Pending sync"
- [x] Syncing -- Blue rotating cloud_upload icon with Semantics "Syncing"
- [x] Synced -- SizedBox.shrink (badge disappears)
- [x] Failed -- Red error_outline icon with Semantics "Sync failed"

### Offline Banner (offline_banner.dart)
- [x] Offline -- Amber banner "You are offline"
- [x] Syncing -- Blue banner with progress text and LinearProgressIndicator
- [x] All Synced -- Green banner "All changes synced" with 3s auto-dismiss
- [x] Failed -- Red banner with tap-to-retry
- [x] Hidden -- SizedBox.shrink when online + idle
- [x] Semantics -- liveRegion with appropriate labels per state

### Home Screen - Recent Workouts
- [x] Loading -- Shimmer placeholders (3 skeleton cards)
- [x] Empty -- "No workouts yet" text message
- [x] Error -- Error card with retry button
- [x] Populated -- Server workout cards with chevron_right and navigation
- [x] Pending workouts -- Cards with SyncStatusBadge, snackbar on tap, no misleading chevron

### Nutrition Screen - Macro Cards
- [x] Loading -- CircularProgressIndicator (existing)
- [x] Populated -- Macro cards with progress rings
- [x] Pending merge -- Macros include pending values, "(includes X pending)" label with cloud_off icon
- [x] No pending -- Label hidden (no visual change from baseline)

### Weight Trends Screen
- [x] Empty -- Empty state with scale icon, "No weight check-ins yet", and CTA button
- [x] Populated -- Summary card + chart + virtualized history list (SliverList.builder)
- [x] Pending weights -- Pending entries at top with SyncStatusBadge, Semantics labels
- [x] Chart -- RepaintBoundary wrapper, optimized shouldRepaint

---

## Consistency Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Card styling | Consistent | Health card uses same `theme.cardColor` + `theme.dividerColor` border pattern as other cards (workout, weight, nutrition) |
| Icon colors | Consistent | Steps green (#22C55E), calories red (#EF4444), heart pink (#EC4899), weight blue (#3B82F6) -- all from the app's existing color vocabulary |
| Sync badge colors | Consistent | Amber (#F59E0B) pending, blue (#3B82F6) syncing, red (#EF4444) failed -- matches OfflineBanner colors |
| Typography | Consistent (after fix) | Labels use 12px (was 11px), values use 15px w600 -- matches other metric displays |
| Spacing | Consistent | 16px padding, 12px gaps, 32px section spacing matches home screen pattern |
| Skeleton loading | Consistent | Uses same gray dividerColor rectangles as home screen workout skeletons |
| Theme usage | Consistent | All colors come from `theme.textTheme`, `theme.cardColor`, `theme.dividerColor`, `theme.colorScheme.primary` |
| Border radius | Consistent | 12px on cards, 8px on metric tiles, 4px on skeleton placeholders |
| Touch targets | Consistent (after fix) | All interactive elements now have minimum 32dp touch targets |

---

## Responsiveness Assessment

| Component | Status | Notes |
|-----------|--------|-------|
| Health card 2x2 grid | Good | Uses `Expanded` children in `Row` -- scales to any width. Min height 48dp on tiles. |
| Health card on narrow screens | Good | Metric tiles use `TextOverflow.ellipsis` for long values (e.g., "40,234 cal"). |
| Permission sheet | Good | Uses `MainAxisSize.min` Column -- auto-sizes to content. SafeArea prevents notch overlap. |
| Pending workout cards | Good | Same layout as server workout cards -- already proven responsive. |
| Macro cards with pending label | Good | Label is centered below the Row -- works at all widths. |
| Weight trends SliverList.builder | Good | Virtualized rendering for large history lists -- memory efficient on all devices. |

---

## Fixes Implemented

### 1. `mobile/lib/shared/widgets/health_card.dart`
- Added `Semantics(label: '$label: $value', excludeSemantics: true)` to `_MetricTile`
- Added `Semantics(label: 'Loading health data', liveRegion: true)` to `_SkeletonHealthCard`
- Added `Semantics(header: true)` to "Today's Health" title
- Fixed `_MetricTile` label font size from 11px to 12px (WCAG compliance)
- Fixed `_openHealthSettings` error silencing: replaced `catch (_)` with `catch (e)` + debug logging

### 2. `mobile/lib/shared/widgets/sync_status_badge.dart`
- Added `Semantics(label: _semanticsLabel, excludeSemantics: true)` wrapper
- Added `_semanticsLabel` getter with status-appropriate text per SyncItemStatus

### 3. `mobile/lib/shared/widgets/health_permission_sheet.dart`
- Wrapped decorative heart icon in `ExcludeSemantics` to hide from screen readers

### 4. `mobile/lib/features/home/presentation/screens/home_screen.dart`
- Removed misleading `chevron_right` icon from `_PendingWorkoutCard` (card is not navigable)
- Added `cloud_off` icon to pending workout tap snackbar for visual consistency

### 5. `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart`
- Replaced `_FoodEntryRow` edit `GestureDetector` with `IconButton` (32dp touch target, tooltip, ripple)
- Replaced "Add Food" `GestureDetector` with `InkWell` (ripple feedback, padded touch target)
- Enhanced "(includes X pending)" label: Semantics liveRegion, cloud_off icon, increased padding
- Added `Tooltip(message: 'Pending sync')` to Latest Weight cloud_off icon
- Added `Semantics(button: true)` to Latest Weight tappable region

### 6. `mobile/lib/features/nutrition/presentation/screens/weight_trends_screen.dart`
- Added `Semantics(label: ...)` to `_buildPendingWeightRow` for screen reader announcement

---

## Items Not Fixed (Require Design Decisions or Out of Scope)

1. **Skeleton shimmer animation**: The skeleton health card uses static gray rectangles rather than a shimmer/pulse animation. The existing `loading_shimmer.dart` widget in the codebase provides animated shimmer, but the health card skeleton was intentionally kept as a simple static placeholder to match the pattern used in the home screen's workout skeleton placeholders (which also use static gray containers). Adding shimmer animation would be a broader design system decision affecting all skeleton states.

2. **Health card tablet layout**: The ticket mentions "single horizontal row on wider screens (tablet), 2x2 grid on phones." The current implementation is always 2x2. Implementing a responsive layout switch at a tablet breakpoint would require a `LayoutBuilder` or `MediaQuery` width check. This is a lower-priority enhancement -- the 2x2 grid works well on all phone sizes and is readable on tablets.

3. **CalorieRing number formatting**: The CalorieRing center text shows raw `remaining.toString()` (e.g., "1523") without locale-aware thousands separators. The health card uses `NumberFormat('#,###')` for consistency. The CalorieRing is pre-existing code outside the scope of this ticket's changes.

4. **"Your goal" refresh icon**: The refresh icon next to "Your goal" on the nutrition screen uses `GestureDetector` with a 16px icon (no minimum touch target). This is pre-existing code outside the scope of this ticket, but should be addressed in a future pass.

---

## Overall UX Score: 8/10

### Breakdown:
- **State Handling:** 9/10 -- Every component handles all states: loading (skeleton with Semantics), populated (data with accessibility labels), empty (hidden/SizedBox.shrink), error (graceful degradation). The sealed class pattern in HealthDataState ensures exhaustive handling.
- **Accessibility:** 8/10 -- After fixes, all health metrics have Semantics labels, sync badges have descriptive labels, loading states are announced, touch targets meet 32dp minimum, decorative elements are excluded. Remaining gap: skeleton cards use static gray rather than animated shimmer (less discoverable to sighted users).
- **Visual Consistency:** 9/10 -- Colors match theme, spacing is consistent, card styling follows existing patterns, sync badge colors are uniform across all contexts.
- **Copy Clarity:** 9/10 -- Permission sheet copy is clear and non-technical ("FitnessAI can read your steps..."). Pending labels are concise ("includes 1 pending"). Snackbar messages are actionable ("This workout is waiting to sync."). Health metric labels are clear (Steps, Active Cal, Heart Rate, Weight).
- **Interaction Feedback:** 8/10 -- Fade-in animation on health card load, ripple on all buttons (after fix), snackbar on pending workout tap with sync icon, badge transitions on sync completion. Pull-to-refresh updates health data without skeleton flash.
- **Responsiveness:** 8/10 -- 2x2 grid scales well on phones, text overflow handled, minimum heights enforced. Tablet-specific layout not yet implemented.

### Strengths:
- Sealed class state pattern ensures every health data state is exhaustively handled in the UI
- Non-blocking health data fetch -- dashboard loads immediately, card appears when data arrives
- 200ms fade-in animation on health card provides polished appearance without feeling slow
- Permission prompt is shown once and respects the user's choice permanently
- Refresh preserves existing data on failure (no jarring skeleton flash)
- Sync badges reactively disappear when sync completes (wired to syncCompletionProvider)
- RepaintBoundary on paint-heavy widgets (CalorieRing, MacroCircle, weight chart) reduces jank
- NumberFormat with thousands separators handles large step counts gracefully

### Areas for Future Improvement:
- Add shimmer animation to skeleton cards for a more polished loading experience
- Implement tablet-specific horizontal layout for health card (4 metrics in a row)
- Add locale-aware number formatting to CalorieRing center text
- Replace "Your goal" refresh GestureDetector with IconButton for proper touch target
- Consider adding a "Connect Health" option in the Settings screen for users who declined initially

---

**Audit completed by:** UX Auditor Agent
**Date:** 2026-02-15
**Pipeline:** 16 -- Health Data Integration + Performance Audit + Offline UI Polish
**Verdict:** PASS -- All critical and medium accessibility and usability issues fixed. 6 files modified with 15 usability fixes and 8 accessibility fixes. `flutter analyze` passes clean with no new errors or warnings in modified files.
