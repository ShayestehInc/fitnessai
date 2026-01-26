from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'role', 'parent_trainer', 'is_active', 'created_at']
    list_filter = ['role', 'is_active', 'created_at']
    search_fields = ['email', 'first_name', 'last_name']
    ordering = ['email']  # Order by email instead of username
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Fitness AI Fields', {
            'fields': ('role', 'parent_trainer', 'phone_number', 'profile_image')
        }),
    )
    # Remove username from fieldsets since we don't use it
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'role'),
        }),
    )
