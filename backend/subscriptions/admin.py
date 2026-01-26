from django.contrib import admin
from .models import Subscription


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ['trainer', 'tier', 'status', 'current_period_start', 'current_period_end']
    list_filter = ['tier', 'status', 'created_at']
    search_fields = ['trainer__email', 'stripe_subscription_id']
    readonly_fields = ['created_at', 'updated_at']
