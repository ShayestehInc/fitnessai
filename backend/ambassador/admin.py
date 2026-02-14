"""
Admin configuration for ambassador app.
"""
from __future__ import annotations

from django.contrib import admin

from .models import AmbassadorCommission, AmbassadorProfile, AmbassadorReferral


@admin.register(AmbassadorProfile)
class AmbassadorProfileAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['user', 'referral_code', 'commission_rate', 'is_active', 'total_referrals', 'total_earnings']
    list_filter = ['is_active', 'created_at']
    search_fields = ['user__email', 'user__first_name', 'user__last_name', 'referral_code']
    readonly_fields = ['referral_code', 'total_referrals', 'total_earnings', 'created_at', 'updated_at']


@admin.register(AmbassadorReferral)
class AmbassadorReferralAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['ambassador', 'trainer', 'referral_code_used', 'status', 'referred_at']
    list_filter = ['status', 'referred_at']
    search_fields = ['ambassador__email', 'trainer__email', 'referral_code_used']
    readonly_fields = ['referred_at', 'activated_at', 'churned_at']


@admin.register(AmbassadorCommission)
class AmbassadorCommissionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ['ambassador', 'commission_amount', 'base_amount', 'commission_rate', 'status', 'period_start', 'period_end']
    list_filter = ['status', 'created_at']
    search_fields = ['ambassador__email']
    readonly_fields = ['created_at']
