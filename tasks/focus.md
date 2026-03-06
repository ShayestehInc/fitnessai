# Focus: Nutrition Phase 3 — LBM Formula Engine & SHREDDED/MASSIVE Templates

## Priority
Build the body composition calculation engine and advanced nutrition template system:

1. **LBM Formula Engine** — Calculate Lean Body Mass from weight + body fat %. Support multiple formulas (Boer, James, Hume). Use LBM to derive more accurate TDEE and macro targets. Integrate with existing NutritionGoal and MacroPreset systems.

2. **SHREDDED Template** — Aggressive fat loss template: high protein (1.2-1.4g/lb LBM), moderate fat, low carbs. Caloric deficit of 20-25%. Includes refeeds.

3. **MASSIVE Template** — Aggressive muscle gain template: high protein (1.0-1.2g/lb LBM), moderate fat, high carbs. Caloric surplus of 10-15%.

4. **Template Assignment Enhancement** — Trainers can assign SHREDDED/MASSIVE (and existing) templates with LBM-based calculations. Auto-recalculate when weight or body fat changes.

## Constraints
- Must integrate with existing NutritionTemplate and NutritionTemplateAssignment models
- LBM calculations require body_fat_percentage on UserProfile (already added in migration 0009)
- Existing macro presets and goals remain backward-compatible
- All formulas must be unit-tested with known reference values
- Mobile UI must show the active template with LBM-derived targets
