# UX Audit: Trainer-Selectable Workout Layouts

## Audit Date: 2026-02-14

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | Medium | _WorkoutLayoutPicker | No error state when API fetch fails — silently falls back to classic | **FIXED:** Added error state with retry button |
| 2 | Medium | _LayoutOption | Border width 1→2px on selection causes 0.5px layout shift | **FIXED:** Compensated padding (12→11, 8→7) when selected |
| 3 | Medium | MinimalWorkoutLayout | Badge size 24x24 vs Classic 28x28 — inconsistent | **FIXED:** Standardized to 28x28 |
| 4 | Low | MinimalWorkoutLayout | Padding horizontal:16,vertical:8 vs Classic all:16 | Minor inconsistency, acceptable |
| 5 | Low | ClassicWorkoutLayout | Weight/reps inputs lack 'lbs'/'reps' suffix unlike Minimal | Could add suffixText for consistency (deferred) |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | AA | TextFields lack explicit semanticLabel | Non-blocking, deferred |

## Missing States
- [x] Loading / skeleton — Loading spinner in _WorkoutLayoutPicker
- [x] Empty / zero data — Default to 'classic' when no config
- [x] Error / failure — **FIXED: Added error state with retry button**
- [x] Success / confirmation — SnackBar on layout update
- [x] Offline / degraded — Falls back to 'classic' default
- [x] Permission denied — Handled at API level

## Fixes Applied
1. **Added error state to _WorkoutLayoutPicker** — When API fetch fails, shows error icon, message, and "Retry" button instead of silently falling back to classic
2. **Fixed border flicker in _LayoutOption** — Compensated padding when border width increases from 1→2px, preventing layout shift
3. **Standardized badge sizing** — MinimalWorkoutLayout badge changed from 24x24 to 28x28 to match ClassicWorkoutLayout
4. **Added type guard on result['data'] cast** — `if (data is Map<String, dynamic>)` guard before casting

## Overall UX Score: 7.5/10
