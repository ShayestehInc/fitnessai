"""Add community_event field to NotificationPreference model."""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0009_add_body_fat_percentage'),
    ]

    operations = [
        migrations.AddField(
            model_name='notificationpreference',
            name='community_event',
            field=models.BooleanField(
                default=True,
                help_text='Notify on community event creation, updates, cancellation, and reminders',
            ),
        ),
    ]
