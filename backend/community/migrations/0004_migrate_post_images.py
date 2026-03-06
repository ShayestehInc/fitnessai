"""
Data migration: copy existing CommunityPost.image values to PostImage rows.
"""
from django.db import migrations


def forward(apps, schema_editor):
    """Copy CommunityPost.image to PostImage for posts that have an image."""
    CommunityPost = apps.get_model("community", "CommunityPost")
    PostImage = apps.get_model("community", "PostImage")

    posts_with_images = CommunityPost.objects.exclude(image="").exclude(image__isnull=True)
    post_images = [
        PostImage(post=post, image=post.image, sort_order=0)
        for post in posts_with_images
    ]
    if post_images:
        PostImage.objects.bulk_create(post_images, batch_size=500)


def backward(apps, schema_editor):
    """Copy first PostImage back to CommunityPost.image."""
    CommunityPost = apps.get_model("community", "CommunityPost")
    PostImage = apps.get_model("community", "PostImage")

    for post_image in PostImage.objects.filter(sort_order=0).select_related("post"):
        CommunityPost.objects.filter(id=post_image.post_id).update(image=post_image.image)


class Migration(migrations.Migration):

    dependencies = [
        ("community", "0003_spaces_and_enhancements"),
    ]

    operations = [
        migrations.RunPython(forward, backward),
    ]
