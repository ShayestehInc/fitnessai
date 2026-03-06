# Code Review: Nutrition Phase 2

## Review Date: 2026-03-05
## Quality Score: 4/10
## Recommendation: BLOCK

## Critical Issues
1. HARDCODED API KEY in food_search_repository.dart:5 (pre-existing)
2. IDOR on summary endpoint — trainer can query any trainee
3. IDOR on active_assignment — trainer can view any trainee
4. Debug print() in food_search_repository.dart (pre-existing)

## Major Issues
5. N+1 in MealLogSerializer — 4x entries.all()
6. Missing FoodItem access control in quick_add
7. No pagination on MealLogViewSet
8. No access control on barcode_lookup
9. Silent exception swallow on date parse in MealLogViewSet
10. display_name CharField on @property (use SerializerMethodField)

## Minor Issues
11. entry_id default 0
12. No delete confirmation on Dismissible
13. Cache active assignment instead of fetching every time
