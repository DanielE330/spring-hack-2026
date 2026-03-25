from rest_framework import serializers
from .models import User, UserDevice


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, required=True)
    user_type_display = serializers.CharField(source='get_user_type_display', read_only=True)
    avatar = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'name', 'surname', 'patronymic', 'password', 'is_admin', 'user_type', 'user_type_display', 'guest_valid_until', 'avatar')
        read_only_fields = ('id', 'user_type', 'guest_valid_until')


class FirstAdminSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, required=True)

    class Meta:
        model = User
        fields = ('email', 'name', 'surname', 'patronymic', 'password')

    def validate(self, data):
        # Санитизация: убираем любые попытки передать is_admin или avatar
        if 'is_admin' in self.initial_data:
            raise serializers.ValidationError("Параметр 'is_admin' не допускается")
        if 'avatar' in self.initial_data:
            raise serializers.ValidationError("Параметр 'avatar' не допускается")
        return data


class ProfileSerializer(serializers.ModelSerializer):
    """Сериализатор для профиля (чтение и частичное редактирование)."""
    user_type_display = serializers.CharField(source='get_user_type_display', read_only=True)
    is_guest = serializers.BooleanField(read_only=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'name', 'surname', 'patronymic', 'is_admin', 'user_type', 'user_type_display', 'guest_valid_until', 'avatar', 'is_guest')
        read_only_fields = ('id', 'email', 'is_admin', 'user_type', 'user_type_display', 'guest_valid_until', 'is_guest')


class AvatarSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('avatar',)

    def validate_avatar(self, value):
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError('Размер файла не должен превышать 5 МБ.')
        if value.content_type not in ('image/jpeg', 'image/png', 'image/webp'):
            raise serializers.ValidationError('Допустимые форматы: JPEG, PNG, WebP.')
        return value


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    device_name = serializers.CharField(required=False, allow_blank=True, default="Unknown")


class LogoutSerializer(serializers.Serializer):
    device_code = serializers.CharField(
        required=False,
        help_text="Ключ устройства (если передан — сессия на устройстве деактивируется)"
    )


class DeviceSerializer(serializers.ModelSerializer):
    is_current = serializers.SerializerMethodField()

    class Meta:
        model = UserDevice
        fields = ('id', 'device_name', 'ip_address', 'is_active', 'last_used', 'created_at', 'is_current')

    def get_is_current(self, obj):
        request_device_code = self.context.get('request_device_code')
        return obj.key == request_device_code


# для swagger
# =====================================================================

class LoginResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    email = serializers.EmailField()
    name = serializers.CharField()
    surname = serializers.CharField()
    patronymic = serializers.CharField(allow_null=True)
    is_admin = serializers.BooleanField()
    avatar = serializers.ImageField(allow_null=True)
    user_type = serializers.CharField()
    user_type_display = serializers.CharField()
    guest_valid_until = serializers.DateTimeField(allow_null=True)
    device_code = serializers.CharField(help_text="Ключ устройства — используется для авторизации")


class MeSerializer(serializers.ModelSerializer):
    user_type_display = serializers.CharField(source='get_user_type_display', read_only=True)
    is_guest = serializers.BooleanField(read_only=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'name', 'surname', 'patronymic', 'is_admin', 'avatar', 'user_type', 'user_type_display', 'guest_valid_until', 'is_guest')
        read_only_fields = fields


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(min_length=8, write_only=True)