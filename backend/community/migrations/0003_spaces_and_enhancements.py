"""
Migration: Add Spaces, SpaceMembership, PostImage, BookmarkCollection, Bookmark models.
Modify CommunityPost (add space FK, is_pinned) and Comment (add parent_comment FK).
"""
import community.models
import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("community", "0002_add_social_features"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # -----------------------------------------------------------------
        # Space
        # -----------------------------------------------------------------
        migrations.CreateModel(
            name="Space",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=200)),
                ("description", models.TextField(blank=True, default="")),
                ("cover_image", models.ImageField(blank=True, upload_to="spaces/covers/")),
                ("emoji", models.CharField(default="💬", max_length=10)),
                ("visibility", models.CharField(
                    choices=[("public", "Public to Cohort"), ("private", "Invite Only")],
                    default="public",
                    max_length=20,
                )),
                ("is_default", models.BooleanField(default=False, help_text="If True, trainees auto-join this space on signup.")),
                ("sort_order", models.PositiveIntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("trainer", models.ForeignKey(
                    limit_choices_to={"role": "TRAINER"},
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="spaces",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                "db_table": "community_spaces",
                "ordering": ["sort_order", "name"],
            },
        ),
        migrations.AddConstraint(
            model_name="space",
            constraint=models.UniqueConstraint(
                fields=["trainer", "name"],
                name="unique_trainer_space_name",
            ),
        ),
        migrations.AddIndex(
            model_name="space",
            index=models.Index(fields=["trainer", "sort_order"], name="community_s_trainer_7e8a2f_idx"),
        ),

        # -----------------------------------------------------------------
        # SpaceMembership
        # -----------------------------------------------------------------
        migrations.CreateModel(
            name="SpaceMembership",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("role", models.CharField(
                    choices=[
                        ("member", "Member"),
                        ("trusted", "Trusted"),
                        ("moderator", "Moderator"),
                        ("admin", "Admin"),
                    ],
                    default="member",
                    max_length=20,
                )),
                ("joined_at", models.DateTimeField(auto_now_add=True)),
                ("is_muted", models.BooleanField(default=False)),
                ("space", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="memberships",
                    to="community.space",
                )),
                ("user", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="space_memberships",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                "db_table": "community_space_memberships",
            },
        ),
        migrations.AddConstraint(
            model_name="spacemembership",
            constraint=models.UniqueConstraint(
                fields=["space", "user"],
                name="unique_space_user_membership",
            ),
        ),
        migrations.AddIndex(
            model_name="spacemembership",
            index=models.Index(fields=["user"], name="community_s_user_id_a1b2c3_idx"),
        ),
        migrations.AddIndex(
            model_name="spacemembership",
            index=models.Index(fields=["space", "role"], name="community_s_space_i_d4e5f6_idx"),
        ),

        # -----------------------------------------------------------------
        # CommunityPost: add space FK and is_pinned
        # -----------------------------------------------------------------
        migrations.AddField(
            model_name="communitypost",
            name="space",
            field=models.ForeignKey(
                blank=True,
                null=True,
                help_text="Optional space this post belongs to",
                on_delete=django.db.models.deletion.CASCADE,
                related_name="posts",
                to="community.space",
            ),
        ),
        migrations.AddField(
            model_name="communitypost",
            name="is_pinned",
            field=models.BooleanField(default=False),
        ),
        migrations.AddIndex(
            model_name="communitypost",
            index=models.Index(fields=["space", "-created_at"], name="community_p_space_i_a9b8c7_idx"),
        ),

        # -----------------------------------------------------------------
        # PostImage
        # -----------------------------------------------------------------
        migrations.CreateModel(
            name="PostImage",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("image", models.ImageField(upload_to=community.models._post_image_upload_path)),
                ("sort_order", models.PositiveIntegerField(default=0)),
                ("post", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="images",
                    to="community.communitypost",
                )),
            ],
            options={
                "db_table": "community_post_images",
                "ordering": ["sort_order"],
            },
        ),
        migrations.AddIndex(
            model_name="postimage",
            index=models.Index(fields=["post", "sort_order"], name="community_p_post_id_e1f2a3_idx"),
        ),

        # -----------------------------------------------------------------
        # Comment: add parent_comment
        # -----------------------------------------------------------------
        migrations.AddField(
            model_name="comment",
            name="parent_comment",
            field=models.ForeignKey(
                blank=True,
                null=True,
                help_text="Parent comment for threaded replies (one level deep).",
                on_delete=django.db.models.deletion.CASCADE,
                related_name="replies",
                to="community.comment",
            ),
        ),
        migrations.AddIndex(
            model_name="comment",
            index=models.Index(fields=["parent_comment"], name="community_c_parent__b4c5d6_idx"),
        ),

        # -----------------------------------------------------------------
        # BookmarkCollection
        # -----------------------------------------------------------------
        migrations.CreateModel(
            name="BookmarkCollection",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=200)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("user", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="bookmark_collections",
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                "db_table": "community_bookmark_collections",
                "ordering": ["name"],
            },
        ),
        migrations.AddConstraint(
            model_name="bookmarkcollection",
            constraint=models.UniqueConstraint(
                fields=["user", "name"],
                name="unique_user_bookmark_collection_name",
            ),
        ),

        # -----------------------------------------------------------------
        # Bookmark
        # -----------------------------------------------------------------
        migrations.CreateModel(
            name="Bookmark",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("user", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="bookmarks",
                    to=settings.AUTH_USER_MODEL,
                )),
                ("post", models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name="bookmarks",
                    to="community.communitypost",
                )),
                ("collection", models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name="bookmarks",
                    to="community.bookmarkcollection",
                )),
            ],
            options={
                "db_table": "community_bookmarks",
                "ordering": ["-created_at"],
            },
        ),
        migrations.AddConstraint(
            model_name="bookmark",
            constraint=models.UniqueConstraint(
                fields=["user", "post"],
                name="unique_user_post_bookmark",
            ),
        ),
        migrations.AddIndex(
            model_name="bookmark",
            index=models.Index(fields=["user", "-created_at"], name="community_b_user_id_f7a8b9_idx"),
        ),
    ]
