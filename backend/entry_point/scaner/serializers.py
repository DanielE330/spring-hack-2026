from rest_framework import serializers
from .models import QRCode, AccessLog, GuestPass


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


class QRValidateUserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    email = serializers.EmailField()
    name = serializers.CharField()
    surname = serializers.CharField()
    patronymic = serializers.CharField(allow_null=True)
    avatar = serializers.URLField(allow_null=True)


class QRValidateResponseSerializer(serializers.Serializer):
    result = serializers.ChoiceField(choices=['granted'])
    attendance_event = serializers.ChoiceField(choices=['entry', 'exit'])
    entered_at = serializers.DateTimeField()
    exited_at = serializers.DateTimeField(allow_null=True)
    worked_seconds = serializers.IntegerField(allow_null=True)
    user = QRValidateUserSerializer()


class AccessLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AccessLog
        fields = ('id', 'scanned_at', 'result', 'reason', 'scanned_by')


# ─── Гостевые пропуска ──────────────────────────────────────────────────────

class GuestPassCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = GuestPass
        fields = (
            'guest_name', 'guest_company', 'purpose', 'note',
            'valid_from', 'valid_until',
        )

    def validate(self, data):
        if data['valid_until'] <= data['valid_from']:
            raise serializers.ValidationError('valid_until должен быть позже valid_from')
        return data


class GuestPassSerializer(serializers.ModelSerializer):
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    is_valid = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)

    class Meta:
        model = GuestPass
        fields = (
            'id', 'guest_name', 'guest_company', 'purpose', 'note',
            'token', 'status',
            'created_by', 'created_by_email', 'created_at',
            'valid_from', 'valid_until',
            'used_at', 'revoked_at',
            'is_valid', 'is_expired',
        )
        read_only_fields = ('id', 'token', 'status', 'created_by', 'created_at', 'used_at', 'revoked_at')


class GuestPassValidateSerializer(serializers.Serializer):
    token = serializers.CharField(help_text="Токен гостевого пропуска")
