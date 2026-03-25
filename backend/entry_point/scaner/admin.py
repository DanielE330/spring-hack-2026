from django.contrib import admin
from .models import QRCode, AccessLog, WeeklyRecord, MonthlyRecord, YearlyRecord, GuestPass


@admin.register(QRCode)
class QRCodeAdmin(admin.ModelAdmin):
    list_display = ('id', 'device', 'token_short', 'is_used', 'created_at', 'expires_at', 'used_at')
    list_filter = ('is_used',)
    search_fields = ('device__user__email', 'token')
    readonly_fields = ('token', 'created_at', 'expires_at', 'used_at')

    def token_short(self, obj):
        return obj.token[:16] + '...'
    token_short.short_description = 'Token'


@admin.register(AccessLog)
class AccessLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'result', 'scanned_at', 'scanned_by', 'reason')
    list_filter = ('result',)
    search_fields = ('scanned_by', 'qr_code__device__user__email')
    readonly_fields = ('scanned_at',)


@admin.register(WeeklyRecord)
class WeeklyRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'week_start', 'week_end', 'days_worked', 'total_hours', 'is_finalized')
    list_filter = ('week_start', 'is_finalized')
    search_fields = ('user__email', 'user__name', 'user__surname')

    def total_hours(self, obj):
        return obj.total_hours
    total_hours.short_description = 'Часы'


@admin.register(MonthlyRecord)
class MonthlyRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'start_date', 'end_date', 'days_worked', 'total_hours', 'is_finalized')
    list_filter = ('year', 'month', 'is_finalized')
    search_fields = ('user__email', 'user__name', 'user__surname')

    def total_hours(self, obj):
        return obj.total_hours
    total_hours.short_description = 'Часы'


@admin.register(YearlyRecord)
class YearlyRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'start_date', 'end_date', 'days_worked', 'total_hours')
    list_filter = ('year',)
    search_fields = ('user__email', 'user__name', 'user__surname')

    def total_hours(self, obj):
        return obj.total_hours
    total_hours.short_description = 'Часы'


@admin.register(GuestPass)
class GuestPassAdmin(admin.ModelAdmin):
    list_display = ('id', 'guest_full_name', 'guest_company', 'purpose', 'status', 'user_email', 'valid_from', 'valid_until', 'created_by')
    list_filter = ('status', 'purpose', 'created_at')
    search_fields = ('guest_surname', 'guest_name', 'guest_patronymic', 'guest_company', 'token', 'user__email')
    readonly_fields = ('token', 'created_at', 'used_at', 'revoked_at')
    fieldsets = (
        ('Информация о госте', {
            'fields': ('guest_surname', 'guest_name', 'guest_patronymic', 'guest_company', 'purpose', 'note')
        }),
        ('Аккаунт (для входа)', {
            'fields': ('user',),
            'description': 'Связанный аккаунт пользователя (если создан)'
        }),
        ('Пропуск', {
            'fields': ('token', 'status', 'valid_from', 'valid_until')
        }),
        ('История', {
            'fields': ('created_by', 'created_at', 'used_at', 'revoked_at'),
            'classes': ('collapse',)
        }),
    )

    def guest_full_name(self, obj):
        return obj.guest_full_name
    guest_full_name.short_description = 'ФИО гостя'

    def user_email(self, obj):
        return obj.user.email if obj.user else '—'
    user_email.short_description = 'Email аккаунта'
