from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0034_add_set_type_to_liftsetlog'),
    ]

    operations = [
        migrations.AddField(
            model_name='trainingplan',
            name='build_mode',
            field=models.CharField(
                blank=True,
                choices=[('quick', 'Quick Build'), ('advanced', 'Advanced Builder')],
                help_text='How this plan was built. Null for legacy/manual plans.',
                max_length=20,
                null=True,
            ),
        ),
        migrations.AddField(
            model_name='trainingplan',
            name='builder_state',
            field=models.JSONField(
                blank=True,
                default=None,
                help_text='Stores builder session state: brief, step progress, choices, explanations.',
                null=True,
            ),
        ),
    ]
