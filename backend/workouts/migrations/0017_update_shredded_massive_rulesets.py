"""Update SHREDDED and MASSIVE system templates with formula-driven rulesets."""

from django.db import migrations


def update_template_rulesets(apps, schema_editor):
    NutritionTemplate = apps.get_model('workouts', 'NutritionTemplate')

    # Update SHREDDED
    try:
        shredded = NutritionTemplate.objects.get(
            template_type='shredded', is_system=True,
        )
        shredded.ruleset = {
            'engine': 'lbm_formula',
            'description': (
                'LBM-based fat-loss template. '
                'Protein: 1.3g/lb LBM. 22% caloric deficit. '
                '3 day types: low_carb, medium_carb, high_carb.'
            ),
            'formula': 'shredded_v1',
            'default_meals_per_day': 6,
            'protein_per_lb_lbm': 1.3,
            'deficit_pct': 22,
            'day_types': ['low_carb', 'medium_carb', 'high_carb'],
            'default_day_type': 'medium_carb',
        }
        shredded.version = 2
        shredded.save()
    except NutritionTemplate.DoesNotExist:
        pass

    # Update MASSIVE
    try:
        massive = NutritionTemplate.objects.get(
            template_type='massive', is_system=True,
        )
        massive.ruleset = {
            'engine': 'lbm_formula',
            'description': (
                'LBM-based muscle-gain template. '
                'Protein: 1.1g/lb LBM. 12% caloric surplus. '
                '2 day types: training_day, rest_day.'
            ),
            'formula': 'massive_v1',
            'default_meals_per_day': 6,
            'protein_per_lb_lbm': 1.1,
            'surplus_pct': 12,
            'day_types': ['training_day', 'rest_day'],
            'default_day_type': 'rest_day',
        }
        massive.version = 2
        massive.save()
    except NutritionTemplate.DoesNotExist:
        pass


def revert_rulesets(apps, schema_editor):
    NutritionTemplate = apps.get_model('workouts', 'NutritionTemplate')

    # Restore original placeholder rulesets from 0013_seed_system_templates
    placeholder_meal = {'name': '', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0}
    placeholder_meals = [placeholder_meal] * 6

    for template_type in ('shredded', 'massive'):
        try:
            tmpl = NutritionTemplate.objects.get(
                template_type=template_type, is_system=True,
            )
            tmpl.version = 1
            tmpl.ruleset = {
                'description': f'Placeholder {template_type} template.',
                'meals_per_day': 6,
                'day_types': {},
                'note': 'Per-meal formulas will be implemented in Phase 3 (LBM engine).',
            }
            tmpl.save()
        except NutritionTemplate.DoesNotExist:
            pass


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0016_fooditem_meallog'),
    ]

    operations = [
        migrations.RunPython(update_template_rulesets, revert_rulesets),
    ]
