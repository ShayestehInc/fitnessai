# Feature: Wire Nutrition Template Assignment into Trainer's Trainee Detail Screen

## Priority
Critical — TemplateAssignmentScreen is built but unreachable from any UI surface.

## User Story
As a trainer, I want to assign a nutrition template to a trainee from their detail screen so that the trainee automatically receives calculated daily macro targets.

## Acceptance Criteria
- [ ] AC-1: Nutrition tab shows "Assign Nutrition Template" button above Macro Presets section
- [ ] AC-2: If trainee has active assignment, show summary card with template name and parameters
- [ ] AC-3: Tapping button navigates to `/nutrition/template-assignment/:traineeId`
- [ ] AC-4: After successful assignment, Nutrition tab refreshes to show the assignment
- [ ] AC-5: Add trainee-parameterized active assignment provider
- [ ] AC-6: Error states handled (network failure, assignment failure)
- [ ] AC-7: Body weight field validation — required before submit

## Edge Cases
1. Trainee has no weight check-ins — fields empty with placeholder text
2. Trainee already has active assignment — show summary card with reassign option
3. Template list is empty — show empty state message
4. Network fails during assignment — error snackbar with retry

## Technical Approach

### Files to modify:
1. `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — Add template assignment section to Nutrition tab
2. `mobile/lib/features/nutrition/presentation/providers/nutrition_template_provider.dart` — Add trainee-parameterized active assignment provider
3. `mobile/lib/features/nutrition/presentation/screens/template_assignment_screen.dart` — Add body weight validation

### No backend changes needed.

## Out of Scope
- Creating nutrition templates from mobile
- Editing template formulas
- Deactivating templates without assigning new one
- Recalculate button on trainer side
