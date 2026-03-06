"""Add NutritionTemplate, NutritionTemplateAssignment, NutritionDayPlan models."""

import django.core.validators
import django.db.models
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('workouts', '0011_checkintemplate_checkinassignment_habit_habitlog_and_more'),
    ]

    operations = [
        # --- NutritionTemplate ---
        migrations.CreateModel(
            name='NutritionTemplate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255)),
                ('template_type', models.CharField(
                    choices=[
                        ('legacy', 'Legacy'),
                        ('shredded', 'Shredded'),
                        ('massive', 'Massive'),
                        ('carb_cycling', 'Carb Cycling'),
                        ('macro_ebook', 'Macro Ebook'),
                        ('custom', 'Custom'),
                    ],
                    default='custom',
                    max_length=20,
                )),
                ('version', models.PositiveIntegerField(default=1)),
                ('ruleset', models.JSONField(
                    default=dict,
                    help_text='Template-type-specific configuration: meal definitions, formulas, day-type mappings, rounding rules',
                )),
                ('is_system', models.BooleanField(
                    default=False,
                    help_text='True for built-in system templates that cannot be edited',
                )),
                ('created_by', models.ForeignKey(
                    blank=True,
                    help_text='Trainer who created this template (null for system templates)',
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='created_nutrition_templates',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'nutrition_templates',
                'ordering': ['name'],
            },
        ),
        migrations.AddIndex(
            model_name='nutritiontemplate',
            index=models.Index(fields=['template_type'], name='nutrition_te_templat_idx'),
        ),
        migrations.AddIndex(
            model_name='nutritiontemplate',
            index=models.Index(fields=['is_system'], name='nutrition_te_is_syst_idx'),
        ),
        migrations.AddIndex(
            model_name='nutritiontemplate',
            index=models.Index(fields=['created_by'], name='nutrition_te_created_idx'),
        ),

        # --- NutritionTemplateAssignment ---
        migrations.CreateModel(
            name='NutritionTemplateAssignment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('parameters', models.JSONField(
                    default=dict,
                    help_text='Trainee-specific parameters: {body_weight_lbs, body_fat_pct, lbm_lbs, meals_per_day}',
                )),
                ('day_type_schedule', models.JSONField(
                    default=dict,
                    help_text="Day-type scheduling config: {method: 'training_based', training_days: 'high_carb', rest_days: 'low_carb'} or {method: 'weekly_rotation', monday: 'high_carb', ...}",
                )),
                ('fat_mode', models.CharField(
                    choices=[('total_fat', 'Total Fat'), ('added_fat', 'Added Fat')],
                    default='total_fat',
                    max_length=20,
                )),
                ('is_active', models.BooleanField(default=True)),
                ('activated_at', models.DateTimeField(auto_now_add=True)),
                ('trainee', models.ForeignKey(
                    limit_choices_to={'role': 'TRAINEE'},
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='nutrition_template_assignments',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('template', models.ForeignKey(
                    on_delete=django.db.models.deletion.PROTECT,
                    related_name='assignments',
                    to='workouts.nutritiontemplate',
                )),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'nutrition_template_assignments',
                'ordering': ['-activated_at'],
            },
        ),
        migrations.AddIndex(
            model_name='nutritiontemplateassignment',
            index=models.Index(fields=['trainee', 'is_active'], name='nut_tmpl_assign_trainee_idx'),
        ),
        migrations.AddConstraint(
            model_name='nutritiontemplateassignment',
            constraint=models.UniqueConstraint(
                condition=models.Q(('is_active', True)),
                fields=['trainee'],
                name='unique_active_nutrition_template_per_trainee',
            ),
        ),

        # --- NutritionDayPlan ---
        migrations.CreateModel(
            name='NutritionDayPlan',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date', models.DateField()),
                ('day_type', models.CharField(
                    choices=[
                        ('training', 'Training Day'),
                        ('rest', 'Rest Day'),
                        ('high_carb', 'High Carb Day'),
                        ('medium_carb', 'Medium Carb Day'),
                        ('low_carb', 'Low Carb Day'),
                        ('refeed', 'Refeed Day'),
                        ('maintenance', 'Maintenance Day'),
                        ('diet_break', 'Diet Break Day'),
                    ],
                    default='training',
                    max_length=20,
                )),
                ('template_snapshot', models.JSONField(
                    default=dict,
                    help_text='Frozen copy of template + parameters at generation time',
                )),
                ('total_protein', models.PositiveIntegerField(default=0)),
                ('total_carbs', models.PositiveIntegerField(default=0)),
                ('total_fat', models.PositiveIntegerField(default=0)),
                ('total_calories', models.PositiveIntegerField(default=0)),
                ('meals', models.JSONField(
                    default=list,
                    help_text='Per-meal targets: [{meal_number, name, protein, carbs, fat, calories}, ...]',
                )),
                ('fat_mode', models.CharField(
                    choices=[('total_fat', 'Total Fat'), ('added_fat', 'Added Fat')],
                    default='total_fat',
                    max_length=20,
                )),
                ('is_overridden', models.BooleanField(
                    default=False,
                    help_text="True if a trainer manually overrode this day's plan",
                )),
                ('trainee', models.ForeignKey(
                    limit_choices_to={'role': 'TRAINEE'},
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='nutrition_day_plans',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'nutrition_day_plans',
                'ordering': ['-date'],
            },
        ),
        migrations.AddIndex(
            model_name='nutritiondayplan',
            index=models.Index(fields=['trainee', 'date'], name='nut_day_plan_trainee_date_idx'),
        ),
        migrations.AddConstraint(
            model_name='nutritiondayplan',
            constraint=models.UniqueConstraint(
                fields=['trainee', 'date'],
                name='unique_nutrition_day_plan_per_date',
            ),
        ),
    ]
