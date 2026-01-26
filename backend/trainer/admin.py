"""
Admin configuration for trainer app.
"""
from django.contrib import admin
from .models import TraineeInvitation, TrainerSession, TraineeActivitySummary


@admin.register(TraineeInvitation)
class TraineeInvitationAdmin(admin.ModelAdmin):
    list_display = ['email', 'trainer', 'status', 'expires_at', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['email', 'trainer__email']
    readonly_fields = ['invitation_code', 'accepted_at', 'created_at']


@admin.register(TrainerSession)
class TrainerSessionAdmin(admin.ModelAdmin):
    list_display = ['trainer', 'trainee', 'started_at', 'ended_at', 'is_read_only']
    list_filter = ['is_read_only', 'started_at']
    search_fields = ['trainer__email', 'trainee__email']
    readonly_fields = ['started_at', 'ended_at', 'actions_log']


@admin.register(TraineeActivitySummary)
class TraineeActivitySummaryAdmin(admin.ModelAdmin):
    list_display = ['trainee', 'date', 'logged_food', 'logged_workout', 'hit_protein_goal']
    list_filter = ['date', 'logged_food', 'logged_workout', 'hit_protein_goal']
    search_fields = ['trainee__email']
    date_hierarchy = 'date'
