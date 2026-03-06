"""
Migrate existing NutritionGoal records to Legacy template assignments.

For each trainee with a NutritionGoal, create a NutritionTemplateAssignment
pointing to the system Legacy template so they seamlessly use the new system.
"""

from django.db import migrations


def migrate_goals_to_legacy(apps, schema_editor):
    NutritionGoal = apps.get_model('workouts', 'NutritionGoal')
    NutritionTemplate = apps.get_model('workouts', 'NutritionTemplate')
    NutritionTemplateAssignment = apps.get_model('workouts', 'NutritionTemplateAssignment')

    legacy_template = NutritionTemplate.objects.filter(
        template_type='legacy',
        is_system=True,
    ).first()

    if legacy_template is None:
        return

    for goal in NutritionGoal.objects.select_related('trainee').iterator():
        already_assigned = NutritionTemplateAssignment.objects.filter(
            trainee=goal.trainee,
            is_active=True,
        ).exists()
        if already_assigned:
            continue

        # Attempt to read meals_per_day from the trainee's profile
        meals_per_day = 4
        try:
            UserProfile = apps.get_model('users', 'UserProfile')
            profile = UserProfile.objects.filter(user=goal.trainee).first()
            if profile and profile.meals_per_day:
                meals_per_day = profile.meals_per_day
        except Exception:
            pass

        NutritionTemplateAssignment.objects.create(
            trainee=goal.trainee,
            template=legacy_template,
            parameters={
                'total_protein': goal.protein_goal,
                'total_carbs': goal.carbs_goal,
                'total_fat': goal.fat_goal,
                'total_calories': goal.calories_goal,
                'meals_per_day': meals_per_day,
            },
            day_type_schedule={
                'method': 'training_based',
                'training_days': 'training',
                'rest_days': 'rest',
            },
            fat_mode='total_fat',
            is_active=True,
        )


def reverse_migration(apps, schema_editor):
    NutritionTemplateAssignment = apps.get_model('workouts', 'NutritionTemplateAssignment')
    NutritionTemplate = apps.get_model('workouts', 'NutritionTemplate')

    legacy_template = NutritionTemplate.objects.filter(
        template_type='legacy',
        is_system=True,
    ).first()

    if legacy_template:
        NutritionTemplateAssignment.objects.filter(
            template=legacy_template,
        ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0013_seed_system_templates'),
        ('users', '0009_add_body_fat_percentage'),
    ]

    operations = [
        migrations.RunPython(migrate_goals_to_legacy, reverse_migration),
    ]
