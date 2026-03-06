# Dev Done: Wire Nutrition Template Assignment into Trainer's Trainee Detail Screen

## Date: 2026-03-05

## Files Changed

### Mobile (Modified)
- `features/trainer/presentation/screens/trainee_detail_screen.dart` — Added `_NutritionTemplateSection` ConsumerWidget to Nutrition tab. Shows "Assign Nutrition Template" button when no active assignment exists, or an assignment summary card with template name, fat mode, and creation date when one does. Modified `_buildNutritionTab` to use Column with Expanded child to avoid nested ListView conflicts.
- `features/nutrition/presentation/providers/nutrition_template_provider.dart` — Added `traineeActiveAssignmentProvider` (FutureProvider.family parameterized by traineeId) for trainer-side active assignment lookup.
- `features/nutrition/presentation/screens/template_assignment_screen.dart` — Added body weight validation in `_submit()`. Shows error snackbar if body weight is empty or <= 0. Removed redundant null check on weight after validation.

## Key Decisions
1. Used `Column` + `Expanded` instead of `ListView` wrapper — `_MacroPresetsTab` already has its own `ListView` as root, nesting would cause scroll conflicts
2. `_NutritionTemplateSection` is a `ConsumerWidget` to access Riverpod providers
3. Both assign button and reassign button invalidate `traineeActiveAssignmentProvider` on return from assignment screen (AC-4)
4. Assignment card shows fat mode chip only when it differs from default ('total_fat')
5. Template name uses `TextOverflow.ellipsis` for long names
6. Body weight validation happens before any state changes or API calls
7. Used existing `/nutrition/template-assignment/:traineeId` route — no router changes needed

## How to Test
1. Navigate to Trainer Dashboard → select a trainee → Nutrition tab
2. Verify "Assign Nutrition Template" button appears above Macro Presets
3. Tap button → should navigate to TemplateAssignmentScreen
4. Try submitting without body weight → should show error snackbar
5. Complete assignment → pop back → should show assignment summary card
6. Tap "Reassign" → should navigate back to assignment screen
