from rest_framework import serializers
from .models import QRCode, AccessLog


class QRGenerateSerializer(serializers.Serializer):
    """Запрос на генерацию QR — тело не нужно, устройство берётся из Authorization."""
    pass


class QRCodeResponseSerializer(serializers.ModelSerializer):
    seconds_left = serializers.SerializerMethodField()
    user_email = serializers.SerializerMethodField()
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = QRCode
        fields = ('token', 'expires_at', 'seconds_left', 'is_used', 'user_email', 'user_name')

    def get_seconds_left(self, obj):
        from django.utils import timezone
        delta = obj.expires_at - timezone.now()
        return max(int(delta.total_seconds()), 0)

    def get_user_email(self, obj):
        return obj.device.user.email

    def get_user_name(self, obj):
        u = obj.device.user
        return f"{u.surname} {u.name} {u.patronymic or ''}".strip()


class QRValidateSerializer(serializers.Serializer):
    token = serializers.CharField(help_text="Значение QR-кода (UUID hex)")


class AccessLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AccessLog
        fields = ('id', 'scanned_at', 'result', 'reason', 'scanned_by')
