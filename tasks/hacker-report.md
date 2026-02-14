# Hacker Report: White-Label Branding

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | settings_screen.dart (Trainer) | "Analytics" tile | Navigate to analytics or show Coming soon | `onTap: () {}` -- taps, animates press, does absolutely nothing. **FIXED** |
| 2 | Medium | settings_screen.dart (Trainer) | "Push Notifications" tile | Navigate or show Coming soon | `onTap: () {}` -- taps, does nothing. **FIXED** |
| 3 | Medium | settings_screen.dart (Trainer) | "Email Notifications" tile | Navigate or show Coming soon | `onTap: () {}` -- taps, does nothing. **FIXED** |
| 4 | Medium | settings_screen.dart (Trainer) | "Help & Support" tile | Navigate or show Coming soon | `onTap: () {}` -- taps, does nothing. **FIXED** |
| 5 | Medium | settings_screen.dart (Trainee) | "Reminders" tile | Navigate or show Coming soon | `onTap: () {}` -- taps, does nothing. **FIXED** |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | branding_preview_card.dart | Logo Image.network shows empty space while loading (no shimmer/spinner) -- jarring pop-in when logo resolves. | **FIXED**: Added `loadingBuilder` with a white CircularProgressIndicator on the primary-color gradient background. |
| 2 | Low | branding_logo_section.dart | Same issue: 96x96 logo in the logo section shows blank space during network load. | **FIXED**: Added `loadingBuilder` with a spinner on translucent primary background. |
| 3 | Low | splash_screen.dart | Custom logo in splash shows blank 120x120 space while loading, then pops in mid-animation. | **FIXED**: Added `loadingBuilder` that shows a spinner on the primary gradient background, matching the default logo container style. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | High | Branding save button | Open branding screen, change nothing, tap "Save Branding" | Button should be disabled if no changes made | Save button was always enabled -- fires unnecessary API calls, no visual feedback that nothing changed. **FIXED**: `_hasUnsavedChanges` getter now gates the save button `onPressed`. Also shows "No unsaved changes" hint text when disabled. |
| 2 | High | Splash screen stale branding | 1. Trainee logs in. 2. Trainer changes branding. 3. Trainee cold-restarts app. | Splash screen reactively shows updated branding from theme provider after fetch. | `_buildBrandedText()` and `_buildLogo()` used `ref.read(themeProvider)` instead of `ref.watch(themeProvider)`. The splash UI wouldn't rebuild when `_fetchTraineeBranding()` updated the provider mid-animation. **FIXED**: Changed to `ref.watch`. |
| 3 | Medium | Leaving branding screen with unsaved changes | 1. Open branding screen. 2. Change app name or colors. 3. Tap back button. | User warned about unsaved changes | No warning -- changes silently discarded. **FIXED**: Wrapped screen in `PopScope` with `canPop: !_hasUnsavedChanges`. Shows confirmation dialog with "Keep Editing" / "Discard" options. |
| 4 | Low | Branding reset to defaults | Trainer wants to un-brand and go back to FitnessAI defaults. | A "Reset" option exists. | No reset mechanism existed -- trainer had to manually pick indigo, clear app name. **FIXED**: Added a "Reset to Defaults" option in the AppBar's popup menu. Resets app name, colors, and removes logo with confirmation dialog. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Branding screen | Add "Preview as trainee" mode that shows a full mock of the home screen/splash with the trainer's branding applied. | The current miniature preview card is nice but doesn't give the trainer confidence about how the full app will look. A full-screen preview (even static) would be 10x more useful. |
| 2 | High | Branding persistence | After trainer saves branding, push the update to connected trainees via WebSocket or push notification so they don't need to restart the app. | Currently trainees only get new branding on fresh login or cold restart. If a trainer changes branding, all connected trainees see stale branding until they restart. |
| 3 | Medium | Color picker | Allow custom hex input -- not just the 12 preset colors. A text field at the bottom of the color picker dialog where the trainer can type any `#RRGGBB` value. | Trainers who have specific brand guidelines (e.g., Pantone-to-hex) cannot match their exact brand color from the 12 presets. |
| 4 | Medium | Logo section | Show the logo dimensions and file size after upload (e.g., "512x512, 245KB"). | Gives the trainer confidence about the image quality and helps debug if the logo looks blurry. |
| 5 | Low | Branding screen | Add a "Copy branding link" button that generates a shareable URL for the trainee onboarding flow pre-configured with this trainer's branding. | Would make onboarding feel more on-brand from the very first screen. |
| 6 | Low | Login screen | The login screen still shows hardcoded "fitnessai" branding regardless of trainer context. If trainees arrive via an invite link, the login screen should show the trainer's branding. | Right now branding is only applied after login, so the first screen the trainee sees is always generic FitnessAI. |

## Items NOT Fixed (Need Design Decisions or Backend Changes)
| # | Severity | Description | Steps to Reproduce | Suggested Approach |
|---|----------|-------------|-------------------|--------------------|
| 1 | Medium | Branding not pushed to trainees in real-time | Trainer saves branding -> trainee sees old branding until cold restart | Add a WebSocket channel or background polling that refreshes branding periodically, or fire a push notification to connected trainees when branding changes. |
| 2 | Low | Login screen not branded for invited trainees | Trainee opens invite link -> sees generic FitnessAI login | Store trainer ID in the invite deeplink, fetch and apply branding before rendering the login screen. Requires invite deeplink architecture. |
| 3 | Low | No hex color input in color picker | Trainer wants exact brand color not in presets | Add a text field to `_showColorPicker` with hex input validation. Use `BrandingModel._hexToColor` to parse. Keep presets above for quick selection. |

## Summary
- Dead UI elements found: 5
- Visual bugs found: 3
- Logic bugs found: 4
- Improvements suggested: 6
- Items fixed by hacker: 12
- Items needing design decisions: 3

## Chaos Score: 7/10
The branding feature is structurally solid but had several quality-of-life gaps that would frustrate a trainer trying to set up their brand. The save button being always enabled was the most user-hostile issue -- trainers would tap Save, see a success toast, and wonder if anything actually happened. The missing unsaved-changes warning was a close second. The dead settings buttons (5 of them!) are not directly related to branding but would erode trust in the settings area where branding lives. All found issues have been fixed or documented.
