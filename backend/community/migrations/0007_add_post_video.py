"""Add PostVideo model for video attachments on community posts."""

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0006_classroom_events_moderation_config'),
    ]

    operations = [
        migrations.CreateModel(
            name='PostVideo',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('file', models.FileField(upload_to='community/posts/videos/%Y/%m/')),
                ('thumbnail', models.ImageField(blank=True, null=True, upload_to='community/posts/thumbnails/%Y/%m/')),
                ('duration', models.FloatField(blank=True, help_text='Video duration in seconds.', null=True)),
                ('file_size', models.PositiveIntegerField(help_text='File size in bytes.')),
                ('sort_order', models.PositiveSmallIntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('post', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='videos', to='community.communitypost')),
            ],
            options={
                'db_table': 'community_post_videos',
                'ordering': ['sort_order'],
            },
        ),
        migrations.AddIndex(
            model_name='postvideo',
            index=models.Index(fields=['post', 'sort_order'], name='community_p_post_id_video_sort_idx'),
        ),
    ]
