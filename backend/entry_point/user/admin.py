from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, UserDevice


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('id', 'email', 'name', 'surname', 'user_type_display', 'is_admin', 'guest_status')
    list_filter = ('is_admin', 'user_type')
    search_fields = ('email', 'name', 'surname')
    ordering = ('email',)
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Личные данные', {'fields': ('name', 'surname', 'patronymic', 'avatar')}),
        ('Тип пользователя', {'fields': ('user_type', 'guest_valid_until')}),
        ('Права', {'fields': ('is_admin', 'is_superuser', 'groups', 'user_permissions')}),
        ('Даты', {'fields': ('last_login',)}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'name', 'surname', 'patronymic', 'password1', 'password2', 'is_admin', 'user_type'),
        }),
    )

    def user_type_display(self, obj):
        return obj.get_user_type_display()
    user_type_display.short_description = 'Тип'

    def guest_status(self, obj):
        if obj.user_type != 'guest':
            return '—'
        from django.utils import timezone
        if obj.guest_valid_until and timezone.now() > obj.guest_valid_until:
            return '❌ Истёк'
        return '✅ Активен'
    guest_status.short_description = 'Статус гостя'


@admin.register(UserDevice)
class UserDeviceAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'device_name', 'ip_address', 'is_active', 'last_used', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('user__email', 'device_name', 'key')
    readonly_fields = ('key', 'created_at')
