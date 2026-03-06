# UX Audit: Wire Nutrition Template Assignment

## Audit Date: 2026-03-05

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | Major | TemplateAssignmentScreen | Error state had no retry button -- users were stuck with "Failed to load templates. Please try again." but no way to retry without leaving the screen | Added retry button (FilledButton.tonal) and error icon for visual clarity |
| 2 | Major | TemplateAssignmentScreen | Empty state was plain text with no icon or visual hierarchy -- felt broken rather than intentional | Added icon, title/subtitle hierarchy, and muted colors to convey "nothing here yet" clearly |
| 3 | Major | TemplateAssignmentScreen | Submitting state did not prevent back navigation -- user could pop mid-request, leaving orphaned server calls | Wrapped body in PopScope with canPop tied to _isSubmitting |
| 4 | Medium | TemplateAssignmentScreen | Success SnackBar used default color while errors used error color -- inconsistent feedback signaling | Added green background and check_circle icon to success SnackBar |
| 5 | Medium | TemplateAssignmentScreen | Body weight validation gave "Body weight is required" for negative numbers -- confusing | Split into three messages: required, must be positive, must be under 1000 |
| 6 | Medium | TemplateAssignmentScreen | Input fields had no helper text -- users had to guess valid ranges and purpose | Added helperText to all three parameter fields |
| 7 | Minor | TemplateAssignmentScreen | Body weight keyboard type was TextInputType.number (integer-only on some platforms) | Changed to TextInputType.numberWithOptions(decimal: true) for decimal weights |
| 8 | Minor | _NutritionTemplateSection | Error text used default color -- did not visually signal an error state | Applied theme.colorScheme.error to error text |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A | No Semantics on loading spinner in _NutritionTemplateSection -- screen readers announce nothing useful | Added Semantics with label "Loading nutrition template assignment" |
| 2 | A | No Semantics on loading spinner in TemplateAssignmentScreen | Added Semantics with label "Loading nutrition templates" |
| 3 | A | No Semantics on the assign button card in _NutritionTemplateSection -- screen readers can't announce the tappable card's purpose | Added Semantics with button: true and descriptive label |
| 4 | A | No Semantics on the active assignment card -- screen readers can't describe what template is active | Added Semantics with label including template name |

## Missing States
- [x] Loading / skeleton -- present in both files, now with Semantics labels
- [x] Empty / zero data -- present (no templates available), improved with icon and hierarchy
- [x] Error / failure -- present in both files; TemplateAssignmentScreen now has retry button
- [x] Success / confirmation -- SnackBar shown on assignment, now with success color and icon
- [x] Disabled / submitting -- FilledButton disabled while _isSubmitting, now also blocks back nav
- [ ] Offline / degraded -- not handled (acceptable; network errors fall through to error state)

## Changes Made

### `mobile/lib/features/nutrition/presentation/screens/template_assignment_screen.dart`
- Error state: added error icon, retry button (FilledButton.tonal), improved layout
- Empty state: added restaurant_menu icon, title/subtitle with visual hierarchy and muted colors
- Parameter fields: added helperText explaining purpose and valid ranges
- Parameter fields: changed keyboard type to numberWithOptions(decimal: true) for weight/body fat
- Body weight validation: split into three distinct error messages (required / positive / under 1000)
- Success SnackBar: added green background and check_circle icon for consistency with error SnackBars
- Loading spinner: wrapped in Semantics with descriptive label
- PopScope: prevents back navigation during form submission

### `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart`
- _NutritionTemplateSection loading: wrapped CircularProgressIndicator in Semantics
- _NutritionTemplateSection error: applied theme.colorScheme.error to error message text
- _buildAssignButton: wrapped entire card in Semantics with button: true and descriptive label
- _buildAssignmentCard: wrapped entire card in Semantics with label including active template name

## Overall UX Score: 7/10

The feature covers all essential states and the form validation is thorough. The main gaps were accessibility (zero Semantics usage), a missing retry mechanism on the error state, and inconsistent success/error feedback styling. All have been addressed. Remaining gap is offline/degraded handling, which is acceptable given the app does not currently have an offline mode.
