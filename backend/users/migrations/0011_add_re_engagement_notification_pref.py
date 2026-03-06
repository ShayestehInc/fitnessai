"""Add re_engagement field to NotificationPreference."""

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0010_add_community_event_notification_pref"),
    ]

    operations = [
        migrations.AddField(
            model_name="notificationpreference",
            name="re_engagement",
            field=models.BooleanField(
                default=True,
                help_text="Notify with re-engagement prompts when inactive (trainee only)",
            ),
        ),
    ]
