from django.contrib import admin
from .models import QRCode, AccessLog, WeeklyRecord, MonthlyRecord, YearlyRecord


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
