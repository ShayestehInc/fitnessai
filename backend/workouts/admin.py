from __future__ import annotations

from django.contrib import admin

from .models import DailyLog, Exercise, Program


@admin.register(Exercise)
class ExerciseAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['name', 'muscle_group', 'is_public', 'created_by', 'created_at']
    list_filter = ['muscle_group', 'is_public', 'created_at']
    search_fields = ['name', 'description']


@admin.register(Program)
class ProgramAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['name', 'trainee', 'start_date', 'end_date', 'is_active', 'created_by']
    list_filter = ['is_active', 'start_date', 'created_at']
    search_fields = ['name', 'trainee__email']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(DailyLog)
class DailyLogAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['trainee', 'date', 'recovery_score', 'steps', 'sleep_hours', 'created_at']
    list_filter = ['date', 'created_at']
    search_fields = ['trainee__email']
    readonly_fields = ['created_at', 'updated_at']
