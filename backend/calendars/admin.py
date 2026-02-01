from __future__ import annotations

from django.contrib import admin

from .models import CalendarConnection, CalendarEvent, TrainerAvailability


@admin.register(CalendarConnection)
class CalendarConnectionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['user', 'provider', 'status', 'calendar_email', 'sync_enabled', 'last_synced_at']
    list_filter = ['provider', 'status', 'sync_enabled']
    search_fields = ['user__email', 'calendar_email']
    readonly_fields = ['created_at', 'updated_at', 'last_synced_at']


@admin.register(CalendarEvent)
class CalendarEventAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['title', 'connection', 'start_time', 'end_time', 'event_type']
    list_filter = ['event_type', 'connection__provider']
    search_fields = ['title', 'description']
    readonly_fields = ['synced_at']


@admin.register(TrainerAvailability)
class TrainerAvailabilityAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['trainer', 'day_of_week', 'start_time', 'end_time', 'is_active']
    list_filter = ['day_of_week', 'is_active']
    search_fields = ['trainer__email']
