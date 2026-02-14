"""
Migration for TrainerBranding model — white-label branding per trainer.
"""
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import trainer.models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('trainer', '0003_add_workout_layout_config'),
    ]

    operations = [
        migrations.CreateModel(
            name='TrainerBranding',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('app_name', models.CharField(
                    blank=True,
                    default='',
                    help_text="Custom app name shown to trainees (e.g. 'FitPro by Coach Jane')",
                    max_length=50,
                )),
                ('primary_color', models.CharField(
                    default='#6366F1',
                    help_text='Primary brand color in hex format (e.g. #6366F1)',
                    max_length=7,
                    validators=[trainer.models.validate_hex_color],
                )),
                ('secondary_color', models.CharField(
                    default='#818CF8',
                    help_text='Secondary brand color in hex format (e.g. #818CF8)',
                    max_length=7,
                    validators=[trainer.models.validate_hex_color],
                )),
                ('logo', models.ImageField(
                    blank=True,
                    help_text='Trainer logo image (JPEG/PNG/WebP, max 2MB, 128x128 to 1024x1024)',
                    null=True,
                    upload_to='branding/',
                )),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('trainer', models.OneToOneField(
                    limit_choices_to={'role': 'TRAINER'},
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='branding',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'db_table': 'trainer_branding',
            },
        ),
    ]
