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
    # Поля для создания аккаунта гостя
    guest_email = serializers.EmailField(required=False, allow_blank=True, help_text="Email для входа гостя")
    guest_password = serializers.CharField(required=False, allow_blank=True, min_length=8, write_only=True, help_text="Пароль для входа гостя")

    class Meta:
        model = GuestPass
        fields = (
            'guest_surname', 'guest_name', 'guest_patronymic',
            'guest_company', 'purpose', 'note',
            'valid_from', 'valid_until',
            'guest_email', 'guest_password',
        )

    def validate(self, data):
        if data['valid_until'] <= data['valid_from']:
            raise serializers.ValidationError('valid_until должен быть позже valid_from')
        
        # Если передан email, требуется пароль
        guest_email = data.get('guest_email', '').strip()
        guest_password = data.get('guest_password', '').strip()
        
        if guest_email and not guest_password:
            raise serializers.ValidationError({'guest_password': 'Пароль обязателен если указан email'})
        
        if guest_password and not guest_email:
            raise serializers.ValidationError({'guest_email': 'Email обязателен если указан пароль'})
        
        return data

    def create(self, validated_data):
        """Создание гостевого пропуска и (опционально) аккаунта пользователя."""
        from django.contrib.auth import get_user_model
        from django.utils import timezone
        
        User = get_user_model()
        
        guest_email = validated_data.pop('guest_email', '').strip()
        guest_password = validated_data.pop('guest_password', '').strip()
        
        # Создаём пропуск
        guest_pass = GuestPass.objects.create(**validated_data)
        
        # Если передан email — создаём аккаунт гостя
        if guest_email:
            # Проверяем что email уникален
            if User.objects.filter(email=guest_email).exists():
                raise serializers.ValidationError({'guest_email': 'Этот email уже используется'})
            
            # Создаём пользователя из полей ФИО пропуска
            user = User.objects.create_user(
                email=guest_email,
                name=guest_pass.guest_name,
                surname=guest_pass.guest_surname,
                patronymic=guest_pass.guest_patronymic,
                password=guest_password,
            )
            user.user_type = 'guest'
            user.guest_valid_until = guest_pass.valid_until
            user.save()
            
            # Связываем пропуск с пользователем
            guest_pass.user = user
            guest_pass.save()
        
        return guest_pass


class GuestPassSerializer(serializers.ModelSerializer):
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    guest_full_name = serializers.CharField(read_only=True)
    is_valid = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    has_account = serializers.SerializerMethodField()
    user_email = serializers.CharField(source='user.email', allow_null=True, read_only=True)

    class Meta:
        model = GuestPass
        fields = (
            'id', 'guest_surname', 'guest_name', 'guest_patronymic',
            'guest_full_name', 'guest_company', 'purpose', 'note',
            'token', 'status',
            'created_by', 'created_by_email', 'created_at',
            'valid_from', 'valid_until',
            'used_at', 'revoked_at',
            'is_valid', 'is_expired',
            'has_account', 'user_email',
        )
        read_only_fields = ('id', 'token', 'status', 'created_by', 'created_at', 'used_at', 'revoked_at')

    def get_has_account(self, obj):
        return obj.user is not None


class GuestPassValidateSerializer(serializers.Serializer):
    token = serializers.CharField(help_text="Токен гостевого пропуска")
