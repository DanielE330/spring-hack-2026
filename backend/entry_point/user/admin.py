from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, UserDevice


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('id', 'email', 'name', 'surname', 'is_admin', 'is_superuser')
    list_filter = ('is_admin',)
    search_fields = ('email', 'name', 'surname')
    ordering = ('email',)
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Личные данные', {'fields': ('name', 'surname', 'patronymic')}),
        ('Права', {'fields': ('is_admin', 'is_superuser', 'groups', 'user_permissions')}),
        ('Даты', {'fields': ('last_login',)}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'name', 'surname', 'patronymic', 'password1', 'password2', 'is_admin'),
        }),
    )


@admin.register(UserDevice)
class UserDeviceAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'device_name', 'ip_address', 'is_active', 'last_used', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('user__email', 'device_name', 'key')
    readonly_fields = ('key', 'created_at')
