# UX Audit: Video Workout Layout

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | Major | `layout-config-selector.tsx` | Labels ("Classic", "Card", "Minimal", "Video") and descriptions are hardcoded English, not using `t()` i18n function. Only the card title/description use `t()`. | Wrap all LAYOUT_OPTIONS labels and descriptions in `t()` calls. |
| 2 | Major | `video_workout_layout.dart` | All user-facing strings are hardcoded English ("Rest", "Skip", "Finish", "Total Time", "Sets", "Max Weight Logged", "Add Set", "Log It", "Current", "Lb"). No i18n support. | Use AppLocalizations or equivalent for all UI strings. |
| 3 | Minor | `layout-config-selector.tsx` | Optimistic update fires immediately on click with no debounce. Rapid clicking cycles through options, sending multiple PATCH requests. | Debounce the mutation or disable buttons until previous mutation settles (already disabled during `isPending`, but `setSelected` is immediate so visual selection jumps ahead of server). |
| 4 | Minor | `video_workout_layout.dart` | Weight unit is hardcoded as "Lb". Users on metric system see the wrong unit. | Pull unit preference from user profile and display "kg" or "Lb" accordingly. |
| 5 | Minor | `exercise-video-player.tsx` | "Video unavailable" error text is hardcoded English, not i18n. | Use `t()` function. |
| 6 | Minor | `video_workout_layout.dart` | The drag indicator at top of logging card suggests the card is draggable, but there is no drag-to-expand behavior. Misleading affordance. | Either implement drag-to-expand or remove the drag indicator. |
| 7 | Minor | `layout-config-selector.tsx` | No error state shown if the initial query fails. `isLoading` shows skeleton, but `isError` is not handled -- the component silently shows the default "classic" selection if the fetch fails. | Add an error state with retry button. |
| 8 | Minor | `exercise-detail-panel.tsx` | Several labels are hardcoded English ("Muscle Group", "Difficulty Level", "Training Goals", "Suitable For", "Edit Exercise", "Save", "Cancel"). Mix of i18n and hardcoded. | Consistently use `t()` for all user-facing strings. |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | AA | `layout-config-selector.tsx`: Layout option buttons lack `aria-pressed` or `role="radio"` semantics. Screen readers cannot tell which option is selected. | Use `role="radiogroup"` on the container and `role="radio"` + `aria-checked` on each button. |
| 2 | AA | `layout-config-selector.tsx`: No visible focus indicator on the layout option buttons. | Add `focus-visible:ring-2 focus-visible:ring-ring` to the button className. |
| 3 | AA | `exercise-video-player.tsx`: YouTube iframe has redundant `title` and `aria-label` with identical text. | Remove `aria-label`; keep `title` for the iframe (standard practice). |
| 4 | A | `video_workout_layout.dart`: Navigation chevrons and circle buttons use `GestureDetector` with no semantic label. Screen readers cannot identify them. | Wrap with `Semantics(label: ..., button: true)` or use `IconButton` with `tooltip`. |
| 5 | A | `video_workout_layout.dart`: "Log It" button per set uses `GestureDetector` with no semantic label. | Add `Semantics(label: 'Log set ${setIndex + 1}', button: true)`. |
| 6 | AA | `video_workout_layout.dart`: Text inputs in the dark logging card have no visible labels. Hint text alone is insufficient. | Add `Semantics(label: ...)` wrappers or use `InputDecoration.labelText`. |
| 7 | AA | `exercise-detail-panel.tsx`: Raw `<select>` dropdowns instead of shadcn Select. Functional but inconsistent with rest of UI. | Consider using shadcn Select component for consistency and better keyboard UX. |

## Missing States
- [x] Loading / skeleton -- `layout-config-selector.tsx` has skeleton loading. Mobile video shows `CircularProgressIndicator` during video init.
- [ ] Empty / zero data -- No handling for empty `exerciseLogs` in `video_workout_layout.dart`. If a workout has zero exercises, `_exercise` getter throws `RangeError`.
- [x] Error / failure -- Video player has error state. Layout config mutation shows toast on error. Mobile video has `_videoError` fallback.
- [x] Success / confirmation -- Toast on layout update. Haptic feedback on set completion.
- [ ] Offline / degraded -- No offline handling. Video fails gracefully (handled), but layout config silently falls back to "classic" with no indication of failure.
- [ ] Permission denied -- No handling if a non-trainer attempts to change layout config. API presumably returns 403 but component shows generic error toast only.

## Overall UX Score: 7/10

The core UX is well-designed -- the video layout is visually polished with good gradients, haptic feedback, and animated transitions. The layout config selector is clean and intuitive. Main gaps: inconsistent i18n coverage across all components, missing accessibility semantics on interactive elements (especially mobile), no empty-state guard for zero exercises, and hardcoded weight units. None are ship-blockers, but the i18n and accessibility gaps should be addressed before shipping to a diverse user base.
