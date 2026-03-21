from rest_framework import serializers
from .models import User, UserDevice


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, required=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'name', 'surname', 'patronymic', 'password', 'is_admin')
        read_only_fields = ('id',)

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        return user


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
    is_admin = serializers.BooleanField()
    device_code = serializers.CharField(help_text="Ключ устройства — используется для авторизации")


class MeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'email', 'name', 'surname', 'patronymic', 'is_admin')
        read_only_fields = fields


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(min_length=8, write_only=True)