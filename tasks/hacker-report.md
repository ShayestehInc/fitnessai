# Hacker Report: Wire Nutrition Template Assignment

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | TemplateAssignmentScreen | "Weekly Rotation" segment button | Should show rotation day configuration (Mon=training, Tue=rest, etc.) | Selects fine but shows zero configuration options; schedule sent to API is just `{'method': 'weekly_rotation'}` with no day mappings. Backend behavior is undefined. Added explanatory hint text as interim fix. |

## Visual Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | _NutritionTemplateSection | Fat mode chip shows raw snake_case `added_fat` instead of "Added Fat" | FIXED - added `_humanFatMode()` helper to display human-readable label |
| 2 | Low | _NutritionTemplateSection | Date chip shows raw ISO date `2026-03-05` instead of "Mar 5, 2026" | FIXED - added `_formatDate()` helper with month name formatting |
| 3 | Low | TemplateAssignmentScreen | Template dropdown text can overflow on long template names | FIXED - added `isExpanded: true` and `TextOverflow.ellipsis` to dropdown |
| 4 | Low | Both files | `const_with_non_const` compile errors on `Semantics` widget wrapped in `const` | FIXED - moved `const` to inner widgets, removed outer `const` |

## Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Medium | Template reassignment | Tap "Reassign" on active assignment card | Confirmation dialog before navigating to assignment screen | Navigated immediately with no confirmation; user could accidentally overwrite active template. FIXED - added AlertDialog confirmation. |
| 2 | Low | Submit with whitespace | Enter " 4 " (with spaces) in meals-per-day field, submit | Should trim and parse correctly | `int.tryParse` was called on untrimmed text; could fail on trailing spaces. FIXED - added `.trim()`. |
| 3 | Low | Submit body fat | Enter " 15 " (with spaces) in body fat field, submit | Should trim and parse correctly | Body fat field trimmed for validation but NOT for the final parse that sends to API; inconsistent behavior could cause `bf` to be null even after validation passed. FIXED - added `.trim()`. |
| 4 | Low | Weekly rotation schedule | Select "Weekly Rotation", fill form, submit | Backend should receive meaningful rotation config | Schedule object sent is `{'method': 'weekly_rotation'}` with no day-type mapping; backend behavior is undefined. Added hint text explaining auto-rotation. |

## Product Improvements
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | TemplateAssignmentScreen | Pre-populate body weight from trainee's latest WeightCheckIn | Trainer shouldn't have to remember/lookup the trainee's weight; it's already in the system |
| 2 | High | _NutritionTemplateSection | Show calculated macro summary (P/C/F/Cal) on the active assignment card | The whole point is macro calculation - trainer needs to see the output at a glance without navigating deeper |
| 3 | Medium | TemplateAssignmentScreen | Show a preview of calculated macros before confirming assignment | Trainer is flying blind - they fill in numbers and hit submit without seeing what the trainee will get |
| 4 | Medium | TemplateAssignmentScreen | Add deactivate/remove option on active assignment (not just reassign) | Currently no way to remove a template assignment without replacing it |
| 5 | Low | TemplateAssignmentScreen | Keyboard should dismiss on scroll or tap outside text fields | Standard UX; currently keyboard stays up and can obscure the submit button |
| 6 | Low | _NutritionTemplateSection | Show template type (e.g., "Carb Cycling", "Standard") on the assignment card | Helps trainer quickly identify which formula is being used |

## Summary
- Dead UI elements found: 1 (Weekly Rotation config is a no-op)
- Visual bugs found: 4
- Logic bugs found: 4
- Improvements suggested: 6
- Items fixed by hacker: 8

## Chaos Score: 5/10
