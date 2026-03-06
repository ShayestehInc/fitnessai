"""Seed system NutritionTemplates."""

from django.db import migrations


SYSTEM_TEMPLATES = [
    {
        'name': 'Legacy',
        'template_type': 'legacy',
        'ruleset': {
            'description': 'Flat daily macros split evenly across meals.',
            'day_types': {},
            'default_meals': [],
        },
    },
    {
        'name': 'Shredded',
        'template_type': 'shredded',
        'ruleset': {
            'description': 'LBM-based fat-loss template with 6 meals, LOW/MED/HIGH carb days.',
            'meals_per_day': 6,
            'day_types': {
                'low_carb': {
                    'meals': [
                        {'name': 'Meal 1 – Breakfast', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
                        {'name': 'Meal 2 – Mid-Morning', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
                        {'name': 'Meal 3 – Pre-Workout', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
                        {'name': 'Meal 4 – Intra/Post-Workout', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
                        {'name': 'Meal 5 – Dinner', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
                        {'name': 'Meal 6 – Before Bed', 'protein': 0, 'carbs': 0, 'fat': 0, 'calories': 0},
                    ],
                },
                'medium_carb': {'meals': []},
                'high_carb': {'meals': []},
            },
            'note': 'Per-meal formulas will be implemented in Phase 3 (LBM engine).',
        },
    },
    {
        'name': 'Massive',
        'template_type': 'massive',
        'ruleset': {
            'description': 'Muscle gain template with surplus-oriented macros.',
            'meals_per_day': 6,
            'day_types': {
                'training': {'meals': []},
                'rest': {'meals': []},
            },
            'note': 'Per-meal formulas will be implemented in Phase 3 (LBM engine).',
        },
    },
    {
        'name': 'Carb Cycling',
        'template_type': 'carb_cycling',
        'ruleset': {
            'description': 'Weekly carb rotation with HIGH/MED/LOW days.',
            'day_types': {
                'high_carb': {'meals': []},
                'medium_carb': {'meals': []},
                'low_carb': {'meals': []},
            },
            'note': 'Full carb cycling engine in Phase 4.',
        },
    },
    {
        'name': 'Macro Ebook',
        'template_type': 'macro_ebook',
        'ruleset': {
            'description': 'Timing-phased nutrition from the Macro Ebook.',
            'day_types': {},
            'note': 'Timing phases will be implemented in Phase 4.',
        },
    },
    {
        'name': 'Custom',
        'template_type': 'custom',
        'ruleset': {
            'description': 'Trainer-defined custom template. Configure meals and day types freely.',
            'day_types': {},
            'default_meals': [],
        },
    },
]


def seed_templates(apps, schema_editor):
    NutritionTemplate = apps.get_model('workouts', 'NutritionTemplate')
    for tmpl in SYSTEM_TEMPLATES:
        NutritionTemplate.objects.get_or_create(
            name=tmpl['name'],
            template_type=tmpl['template_type'],
            is_system=True,
            defaults={
                'version': 1,
                'ruleset': tmpl['ruleset'],
            },
        )


def remove_templates(apps, schema_editor):
    NutritionTemplate = apps.get_model('workouts', 'NutritionTemplate')
    NutritionTemplate.objects.filter(is_system=True).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0012_nutrition_templates'),
    ]

    operations = [
        migrations.RunPython(seed_templates, remove_templates),
    ]
