"""Add body_fat_percentage to UserProfile."""

import django.core.validators
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0008_add_notification_preference'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='body_fat_percentage',
            field=models.FloatField(
                blank=True,
                help_text='Body fat percentage for LBM-based nutrition calculations',
                null=True,
                validators=[
                    django.core.validators.MinValueValidator(3.0),
                    django.core.validators.MaxValueValidator(60.0),
                ],
            ),
        ),
    ]
