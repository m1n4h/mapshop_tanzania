from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'phone_number', 'user_type', 'is_verified', 'is_active')
    list_filter = ('user_type', 'is_verified', 'is_active')
    search_fields = ('email', 'username', 'phone_number')
    ordering = ('-date_joined',)
    
    fieldsets = UserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('phone_number', 'user_type', 'profile_picture', 'location', 'address', 'is_verified', 'otp_code', 'fcm_token')}),
    )

admin.site.register(User, CustomUserAdmin)