"""Add builder intelligence fields: phases, day roles, session families, pairing, tempo, timing."""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0035_trainingplan_builder_fields'),
    ]

    operations = [
        # PlanWeek: add phase
        migrations.AddField(
            model_name='planweek',
            name='phase',
            field=models.CharField(
                choices=[
                    ('on_ramp', 'On-Ramp / Re-Entry'),
                    ('accumulation', 'Accumulation / Build'),
                    ('intensification', 'Intensification'),
                    ('realization', 'Realization / Peak'),
                    ('deload', 'Deload / Reset'),
                    ('bridge', 'Bridge / Maintenance'),
                ],
                default='accumulation',
                help_text='Training phase for this week.',
                max_length=20,
            ),
        ),

        # PlanSession: add day_role, session_family, day_stress, estimated_duration_minutes
        migrations.AddField(
            model_name='plansession',
            name='day_role',
            field=models.CharField(
                blank=True, default='', max_length=50,
                help_text='Day role classification.',
            ),
        ),
        migrations.AddField(
            model_name='plansession',
            name='session_family',
            field=models.CharField(
                choices=[
                    ('strength', 'Strength'),
                    ('hypertrophy', 'Hypertrophy'),
                    ('power_athletic', 'Power / Athletic'),
                    ('conditioning', 'Conditioning'),
                    ('technique', 'Technique'),
                    ('rehab_tolerance', 'Rehab / Tolerance'),
                    ('mixed_hybrid', 'Mixed Hybrid'),
                ],
                default='mixed_hybrid',
                max_length=20,
                help_text='Session family classification.',
            ),
        ),
        migrations.AddField(
            model_name='plansession',
            name='day_stress',
            field=models.CharField(
                choices=[
                    ('high_neural', 'High Neural'),
                    ('medium_mixed', 'Medium Mixed'),
                    ('low_neural', 'Low Neural / Low Ortho'),
                    ('local_fatigue', 'Local Fatigue Dominant'),
                    ('aerobic', 'Aerobic Dominant'),
                    ('restore', 'Restore'),
                    ('optional', 'Optional'),
                ],
                default='medium_mixed',
                max_length=20,
                help_text='Neural/orthopedic stress level.',
            ),
        ),
        migrations.AddField(
            model_name='plansession',
            name='estimated_duration_minutes',
            field=models.PositiveIntegerField(
                blank=True, null=True,
                help_text='Estimated session duration in minutes.',
            ),
        ),

        # PlanSlot: add pairing_group, pairing_type, tempo_preset, is_optional
        migrations.AddField(
            model_name='planslot',
            name='pairing_group',
            field=models.PositiveIntegerField(
                blank=True, null=True,
                help_text='Shared integer for paired slots. Null = standalone.',
            ),
        ),
        migrations.AddField(
            model_name='planslot',
            name='pairing_type',
            field=models.CharField(
                choices=[
                    ('straight', 'Straight Sequencing'),
                    ('superset_antagonist', 'Superset (Antagonist)'),
                    ('superset_non_competing', 'Superset (Non-Competing)'),
                    ('superset_agonist', 'Superset (Agonist)'),
                    ('tri_set', 'Tri-Set'),
                    ('giant_set', 'Giant Set'),
                    ('contrast', 'Contrast Pair'),
                    ('complex', 'Complex'),
                    ('potentiation', 'Potentiation Pair'),
                ],
                default='straight',
                max_length=25,
                help_text='Pairing method for this slot.',
            ),
        ),
        migrations.AddField(
            model_name='planslot',
            name='tempo_preset',
            field=models.CharField(
                blank=True,
                choices=[
                    ('power_speed', 'Power / Speed'),
                    ('general_strength', 'General Strength'),
                    ('pause_strength', 'Pause Strength'),
                    ('joint_friendly', 'Joint-Friendly Control'),
                    ('lengthened_hypertrophy', 'Lengthened-Bias Hypertrophy'),
                    ('technique_preset', 'Technique / Strategy'),
                    ('rehab_tolerance', 'Rehab Tolerance'),
                ],
                max_length=25,
                null=True,
                help_text='Tempo preset for this slot.',
            ),
        ),
        migrations.AddField(
            model_name='planslot',
            name='is_optional',
            field=models.BooleanField(
                default=False,
                help_text='Optional slots are first to be cut when session runs long.',
            ),
        ),
    ]
