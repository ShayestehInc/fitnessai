"""
Admin configuration for features app.
"""
from __future__ import annotations

from django.contrib import admin

from .models import FeatureComment, FeatureRequest, FeatureVote


@admin.register(FeatureRequest)
class FeatureRequestAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['title', 'category', 'status', 'submitted_by', 'upvotes', 'downvotes', 'created_at']
    list_filter = ['status', 'category', 'created_at']
    search_fields = ['title', 'description', 'submitted_by__email']
    readonly_fields = ['upvotes', 'downvotes', 'created_at', 'updated_at']
    list_editable = ['status']


@admin.register(FeatureVote)
class FeatureVoteAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['feature', 'user', 'vote_type', 'created_at']
    list_filter = ['vote_type', 'created_at']
    search_fields = ['feature__title', 'user__email']


@admin.register(FeatureComment)
class FeatureCommentAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['feature', 'user', 'is_admin_response', 'created_at']
    list_filter = ['is_admin_response', 'created_at']
    search_fields = ['feature__title', 'user__email', 'content']
