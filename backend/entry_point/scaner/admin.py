from django.contrib import admin
from .models import QRCode, AccessLog, AttendanceRecord


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


@admin.register(AttendanceRecord)
class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'date', 'entered_at', 'exited_at')
    list_filter = ('date',)
    search_fields = ('user__email', 'user__name', 'user__surname')
    readonly_fields = ('entered_at', 'exited_at')
