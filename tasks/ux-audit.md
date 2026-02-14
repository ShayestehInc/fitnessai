# UX Audit: White-Label Branding Infrastructure

## Audit Date: 2026-02-14

## Files Audited
- `mobile/lib/features/settings/presentation/screens/branding_screen.dart`
- `mobile/lib/features/settings/presentation/widgets/branding_preview_card.dart`
- `mobile/lib/features/settings/presentation/widgets/branding_logo_section.dart`
- `mobile/lib/features/settings/presentation/widgets/branding_color_section.dart`
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart`
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | High | BrandingScreen | Save button always enabled even when no changes made -- trainer gets no signal about whether they have unsaved work | **FIXED:** Save button now disabled when no changes detected; shows "No unsaved changes" helper text |
| 2 | High | BrandingScreen | No way to undo/reset branding to defaults -- trainer stuck if they made bad changes | **FIXED:** Added "Reset to Defaults" option in AppBar overflow menu with confirmation dialog |
| 3 | High | BrandingScreen | No unsaved-changes guard when navigating away -- trainer loses work silently | **FIXED:** Added PopScope with confirmation dialog when user has unsaved changes |
| 4 | Medium | BrandingScreen (removeLogo) | No success feedback when logo is removed -- silent removal feels broken | **FIXED:** Added green SnackBar "Logo removed" on successful removal |
| 5 | Medium | BrandingScreen (removeLogo) | "Remove" button in confirmation dialog not styled as destructive -- looks identical to "Cancel" | **FIXED:** Styled "Remove" button with error color |
| 6 | Medium | BrandingColorSection | Color picker selected indicator uses white border/checkmark on all colors -- invisible on light colors like Amber, Cyan | **FIXED:** Added luminance-based contrast detection; light colors get dark indicator, dark colors get white indicator |
| 7 | Medium | BrandingPreviewCard | "Start Workout" sample button uses white text on all primary colors -- unreadable on light colors | **FIXED:** Added luminance check for text color contrast on primary button |
| 8 | Low | BrandingLogoSection | Loading state shows only a spinner with no label -- user doesn't know if uploading or processing | **FIXED:** Added "Uploading logo..." label below spinner |
| 9 | Low | SettingsScreen | Analytics tile has empty onTap handler -- appears tappable (with chevron) but does nothing | Noted -- not in scope for branding feature, but flagged for future fix |
| 10 | Low | SettingsScreen | Push Notifications, Email Notifications, Help & Support tiles have empty onTap handlers | Noted -- pre-existing dead UI, not in scope |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A | No Semantics labels on any interactive branding elements -- screen readers cannot describe buttons, color swatches, or preview | **FIXED:** Added Semantics wrappers to: save button, color rows, color picker swatches, logo buttons, preview card |
| 2 | A | Color picker GestureDetector has no semantic description | **FIXED:** Each swatch now has `Semantics(button: true, selected:, label: 'Color #XXXXXX')` |
| 3 | A | Logo image has no semantic image label | **FIXED:** Added `Semantics(image: true, label: 'Current logo')` to the logo display |
| 4 | AA | Color picker swatch check icon (white) invisible on light-colored swatches -- fails WCAG contrast | **FIXED:** Dynamic indicator color based on luminance threshold |

## Missing States
- [x] Loading / skeleton -- CircularProgressIndicator while fetching branding
- [x] Empty / zero data -- Default FitnessAI colors shown; text field shows hint "FitnessAI"
- [x] Error / failure -- Error state with retry button; SnackBars on save/upload failures
- [x] Success / confirmation -- Green SnackBars on save, upload, and removal
- [x] Offline / degraded -- Splash screen uses cached branding; error state has retry
- [x] Permission denied -- Row-level security on backend; only trainers see Branding in settings

## Fixes Applied

### 1. Save Button Disables When No Changes (branding_screen.dart)
- Added `_originalAppName`, `_originalPrimaryColor`, `_originalSecondaryColor` tracking fields
- Added `_hasUnsavedChanges` getter that compares current values to originals
- Save button is now disabled (`onPressed: null`) when no changes detected
- Shows "No unsaved changes" hint text below the disabled button
- Originals update after successful save

### 2. Reset to Defaults (branding_screen.dart)
- Added "Reset to Defaults" in AppBar overflow menu (PopupMenuButton)
- Confirmation dialog explains impact: "Your trainees will see the default FitnessAI branding"
- Reset clears app name, resets both colors to defaults, removes logo via API
- "Reset" button styled in error color for destructive action clarity

### 3. Unsaved Changes Guard (branding_screen.dart)
- Wrapped Scaffold in `PopScope(canPop: !_hasUnsavedChanges)`
- When user tries to navigate away with unsaved changes, shows dialog: "You have unsaved branding changes. Discard them?"
- "Keep Editing" vs "Discard" options; Discard styled in error color

### 4. Logo Removal Success SnackBar (branding_screen.dart)
- Added green SnackBar "Logo removed" on successful logo deletion
- Previously only error case showed feedback; success was silent

### 5. Destructive Button Styling (branding_screen.dart)
- "Remove" button in logo removal confirmation dialog now uses `Theme.of(context).colorScheme.error`
- Visual distinction from non-destructive "Cancel" action

### 6. Color Picker Contrast Fix (branding_color_section.dart)
- Added `_isLightColor(Color)` helper using `color.computeLuminance() > 0.4`
- Added `_indicatorColor(Color)` that returns dark (#1A1A1A) for light colors, white for dark colors
- Check icon and selection border now use dynamic indicator color
- Amber, Cyan, and other light swatches are now clearly marked when selected

### 7. Preview Button Contrast (branding_preview_card.dart)
- "Start Workout" sample button text color now adapts based on primary color luminance
- Light primary colors get dark text; dark primary colors get white text

### 8. Upload Progress Label (branding_logo_section.dart)
- Added "Uploading logo..." text below the CircularProgressIndicator during upload
- Uses theme's bodySmall color for consistency

### 9. Accessibility Labels (all widget files)
- `BrandingPreviewCard`: Semantics label describing preview purpose and displayed name
- `BrandingLogoSection`: Semantics on logo image, Replace button, Remove button, Choose Image button
- `BrandingColorSection`: Semantics on each color row with label/hex/subtitle; Semantics on each picker swatch with hex and selected state
- `BrandingScreen`: Semantics on save button with enabled state and label

## Items Not Fixed (Out of Scope)
1. Settings screen has several tiles with empty `onTap: () {}` (Analytics, Push/Email Notifications, Help & Support) -- these are pre-existing dead UI elements, not part of the branding feature
2. Splash screen branding flow is well-implemented with proper error handling and caching -- no changes needed

## Overall UX Score: 8/10

The branding feature was already well-structured with proper loading, error, and success states. The main gaps were around change detection (save button always enabled), undo capability (no reset), and accessibility (no Semantics). All critical and medium issues have been fixed. The feature now meets the standard of: would a designer at Stripe approve this? Yes, with the caveat that the color picker could eventually be upgraded to a full HSL picker instead of presets only.
