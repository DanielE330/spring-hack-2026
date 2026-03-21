import logging

from django.utils import timezone
from datetime import timedelta
from django.core.mail import send_mail
from django.conf import settings as django_settings
from rest_framework.generics import CreateAPIView, GenericAPIView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import authenticate
import secrets
from .models import User, UserDevice, PasswordResetToken
from .serializers import (
    LoginResponseSerializer, UserSerializer, LoginSerializer,
    MeSerializer, DeviceSerializer, LogoutSerializer,
    PasswordResetRequestSerializer, PasswordResetConfirmSerializer,
)
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiResponse
from drf_spectacular.types import OpenApiTypes

logger = logging.getLogger('user')


# cоздание первого админа !!!бд должна быть пуста!!!
@extend_schema(
    summary="Создание первого администратора",
    description="Создает первого пользователя с правами администратора. Доступно только если база данных пуста",
    request=UserSerializer,
    responses={
        201: OpenApiResponse(description="Администратор успешно создан"),
        403: OpenApiResponse(description="Ошибка: администратор уже существует"),
        400: OpenApiResponse(description="Ошибка валидации данных"),
    },
    tags=["Admin"])
class FirstAdminView(CreateAPIView):
    serializer_class = UserSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        logger.info("[FirstAdminView] Запрос на создание первого администратора")

        if User.objects.filter(is_admin=True).exists():
            logger.warning("[FirstAdminView] Попытка создать первого админа, но он уже существует")
            return Response({"detail": "администратор уже существует. Используйте вход."},
                             status=status.HTTP_403_FORBIDDEN)

        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            logger.warning("[FirstAdminView] Ошибка валидации: %s", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        data['is_admin'] = True
        logger.debug("[FirstAdminView] Данные прошли валидацию, email=%s", data.get('email'))

        user = User.objects.create_user(
            email=data['email'],
            name=data['name'],
            surname=data['surname'],
            patronymic=data.get('patronymic'),
            password=data['password'],
            is_admin=True
        )
        logger.info("[FirstAdminView] Первый администратор создан: id=%s email=%s", user.id, user.email)

        return Response({"message": "Первый админ создан", "email": user.email}, status=status.HTTP_201_CREATED)


# 2. Создание пользователей
@extend_schema(
    summary="Создание нового пользователя",
    description="Создает нового пользователя. Доступно только авторизованным администраторам.",
    request=UserSerializer,
    responses={
        201: OpenApiResponse(description="Пользователь успешно создан"),
        401: OpenApiResponse(description="Ошибка: не авторизован"),
        400: OpenApiResponse(description="Ошибка валидации данных"),
        403: OpenApiResponse(description="Ошибка: недостаточно прав"),
    },
    tags=["Admin"]
    )
class CreateUserView(CreateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        logger.info(
            "[CreateUserView] Запрос на создание пользователя от: id=%s email=%s is_admin=%s",
            request.user.id, request.user.email, request.user.is_admin
        )

        if not request.user.is_admin:
            logger.warning(
                "[CreateUserView] Отказано в доступе — пользователь id=%s не является администратором",
                request.user.id
            )
            return Response({"detail": "Только администраторы могут создавать пользователей."}, status=status.HTTP_403_FORBIDDEN)

        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            logger.warning("[CreateUserView] Ошибка валидации: %s", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        if 'is_admin' not in data:
            data['is_admin'] = False
        logger.debug(
            "[CreateUserView] Данные валидны, создаю пользователя email=%s is_admin=%s",
            data.get('email'), data.get('is_admin')
        )

        user = User.objects.create_user(
            email=data['email'],
            name=data['name'],
            surname=data['surname'],
            patronymic=data.get('patronymic'),
            password=data['password'],
            is_admin=data.get('is_admin', False),
        )
        logger.info("[CreateUserView] Пользователь создан: id=%s email=%s", user.id, user.email)

        return Response({"message": "Пользователь создан", "id": user.id}, status=status.HTTP_201_CREATED)


class LoginView(GenericAPIView):
    serializer_class = LoginSerializer
    permission_classes = [AllowAny]

    @extend_schema(
    summary="Вход в систему",
    description="Аутентификация пользователя по email и паролю. Создает запись устройства и возвращает данные пользователя вместе с ключом устройства (device_code), который используется для авторизации всех дальнейших запросов.",
    request=LoginSerializer,
    responses={
        200: OpenApiResponse(description="Успешный вход", response=LoginResponseSerializer),
        401: OpenApiResponse(description="Ошибка: неверный email или пароль"),
        400: OpenApiResponse(description="Ошибка валидации данных"),
    },
    tags=["User"]
    )
    def post(self, request, *args, **kwargs):
        logger.info("[LoginView] Запрос на вход")

        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            logger.warning("[LoginView] Ошибка валидации: %s", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        device_name = serializer.validated_data.get('device_name')
        logger.debug("[LoginView] Попытка входа email=%s device_name=%s", email, device_name)

        user = authenticate(username=email, password=password)

        if not user:
            logger.warning("[LoginView] Неудачная попытка входа для email=%s", email)
            return Response({"detail": "Неверный email или пароль"}, status=status.HTTP_401_UNAUTHORIZED)

        device = UserDevice.objects.create(user=user, device_name=device_name)
        logger.info(
            "[LoginView] Успешный вход: id=%s email=%s device_name=%s",
            user.id, user.email, device_name
        )

        return Response({
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "surname": user.surname,
            "is_admin": user.is_admin,
            "device_code": device.key,
        }, status=status.HTTP_200_OK)


@extend_schema(
    summary="Текущий пользователь",
    description="Возвращает данные авторизованного пользователя по access-токену.",
    responses={
        200: OpenApiResponse(description="Данные пользователя", response=MeSerializer),
        401: OpenApiResponse(description="Не авторизован"),
    },
    tags=["User"]
)
class MeView(GenericAPIView):
    serializer_class = MeSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        logger.info("[MeView] Запрос данных текущего пользователя id=%s", request.user.id)
        serializer = self.get_serializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)


@extend_schema(
    summary="Выход из системы",
    description="Деактивирует сессию устройства. Передайте device_code или используется текущее устройство из заголовка Authorization.",
    request=LogoutSerializer,
    responses={200: OpenApiResponse(description="Выход выполнен")},
    tags=["Auth"]
)
class LogoutView(GenericAPIView):
    serializer_class = LogoutSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        logger.info("[LogoutView] Запрос на выход, user_id=%s", request.user.id)
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Удаляем устройство из БД
        device_code = serializer.validated_data.get('device_code')

        if device_code:
            deleted, _ = UserDevice.objects.filter(
                key=device_code, user=request.user
            ).delete()
            logger.info("[LogoutView] Удалено устройств по device_code: %s", deleted)
        elif hasattr(request, 'auth') and isinstance(request.auth, UserDevice):
            device_id = request.auth.id
            request.auth.delete()
            logger.info("[LogoutView] Удалено текущее устройство id=%s", device_id)

        return Response({"detail": "Выход выполнен"}, status=status.HTTP_200_OK)


@extend_schema(
    summary="Список устройств пользователя",
    description="Возвращает список всех устройств (сессий) текущего пользователя. is_current=true — текущее устройство.",
    responses={200: OpenApiResponse(description="Список устройств")},
    tags=["Devices"]
)
class DeviceListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        logger.info("[DeviceListView] user_id=%s", request.user.id)
        current_device = getattr(request, 'auth', None)
        current_key = current_device.key if isinstance(current_device, UserDevice) else None
        devices = UserDevice.objects.filter(user=request.user).order_by('-created_at')
        serializer = DeviceSerializer(
            devices, many=True,
            context={'request_device_code': current_key}
        )
        return Response(serializer.data)


@extend_schema(
    summary="Завершить сессию своего устройства",
    description="Деактивирует сессию на конкретном устройстве пользователя. Удалить чужое — нельзя.",
    responses={
        200: OpenApiResponse(description="Сессия завершена"),
        404: OpenApiResponse(description="Устройство не найдено"),
    },
    tags=["Devices"]
)
class DeviceDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, device_id, *args, **kwargs):
        logger.info("[DeviceDeleteView] user_id=%s device_id=%s", request.user.id, device_id)
        try:
            device = UserDevice.objects.get(id=device_id, user=request.user)
        except UserDevice.DoesNotExist:
            logger.warning("[DeviceDeleteView] Устройство %s не найдено для user_id=%s", device_id, request.user.id)
            return Response({"detail": "Устройство не найдено"}, status=status.HTTP_404_NOT_FOUND)

        device.delete()
        logger.info("[DeviceDeleteView] Устройство %s удалено", device_id)
        return Response({"detail": "Сессия завершена"}, status=status.HTTP_200_OK)


@extend_schema(
    summary="[Админ] Принудительно завершить любую сессию",
    description="Доступно только администраторам. Деактивирует любое устройство любого пользователя.",
    responses={
        200: OpenApiResponse(description="Сессия завершена"),
        403: OpenApiResponse(description="Недостаточно прав"),
        404: OpenApiResponse(description="Устройство не найдено"),
    },
    tags=["Admin"]
)
class AdminDeviceDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, device_id, *args, **kwargs):
        if not request.user.is_admin:
            return Response({"detail": "Недостаточно прав"}, status=status.HTTP_403_FORBIDDEN)

        logger.info("[AdminDeviceDeleteView] admin_id=%s -> device_id=%s", request.user.id, device_id)
        try:
            device = UserDevice.objects.get(id=device_id)
        except UserDevice.DoesNotExist:
            return Response({"detail": "Устройство не найдено"}, status=status.HTTP_404_NOT_FOUND)

        device.delete()
        logger.info("[AdminDeviceDeleteView] Устройство %s удалено админом", device_id)
        return Response({"detail": "Сессия завершена"}, status=status.HTTP_200_OK)


@extend_schema(
    summary="Запрос сброса пароля",
    description="Отправляет письмо с токеном для сброса пароля на указанный email. Всегда возвращает 200 (даже если email не найден).",
    request=PasswordResetRequestSerializer,
    responses={200: OpenApiResponse(description="Письмо отправлено (если email существует)")},
    tags=["Auth"],
)
class PasswordResetRequestView(GenericAPIView):
    serializer_class = PasswordResetRequestSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Не раскрываем существование email
            return Response({"detail": "Если email зарегистрирован, письмо будет отправлено."}, status=status.HTTP_200_OK)

        timeout = getattr(django_settings, 'PASSWORD_RESET_TIMEOUT_MINUTES', 30)
        token = secrets.token_urlsafe(32)
        expires_at = timezone.now() + timedelta(minutes=timeout)
        PasswordResetToken.objects.create(user=user, token=token, expires_at=expires_at)

        send_mail(
            subject="Сброс пароля",
            message=(
                f"Вы запросили сброс пароля.\n\n"
                f"Ваш токен: {token}\n\n"
                f"Токен действителен {timeout} минут.\n\n"
                f"Для смены пароля отправьте POST-запрос на /auth/password-reset/confirm/ "
                f"с полями token и new_password.\n\n"
                f"Если вы не запрашивали сброс пароля — проигнорируйте это письмо."
            ),
            from_email=django_settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )
        logger.info("[PasswordResetRequestView] Токен сброса пароля отправлен на %s", email)
        return Response({"detail": "Если email зарегистрирован, письмо будет отправлено."}, status=status.HTTP_200_OK)


@extend_schema(
    summary="Подтверждение сброса пароля",
    description="Принимает токен из письма и новый пароль. Меняет пароль пользователя.",
    request=PasswordResetConfirmSerializer,
    responses={
        200: OpenApiResponse(description="Пароль успешно изменён"),
        400: OpenApiResponse(description="Токен недействителен или истёк"),
    },
    tags=["Auth"],
)
class PasswordResetConfirmView(GenericAPIView):
    serializer_class = PasswordResetConfirmSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        token_str = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']

        try:
            reset_token = PasswordResetToken.objects.select_related('user').get(token=token_str)
        except PasswordResetToken.DoesNotExist:
            return Response({"detail": "Токен недействителен."}, status=status.HTTP_400_BAD_REQUEST)

        if not reset_token.is_valid():
            return Response({"detail": "Токен истёк или уже использован."}, status=status.HTTP_400_BAD_REQUEST)

        user = reset_token.user
        user.set_password(new_password)
        user.save()

        reset_token.is_used = True
        reset_token.save(update_fields=['is_used'])

        # Деактивируем все сессии пользователя для безопасности
        UserDevice.objects.filter(user=user).delete()

        logger.info("[PasswordResetConfirmView] Пароль изменён для user_id=%s", user.id)
        return Response({"detail": "Пароль успешно изменён. Все сессии завершены."}, status=status.HTTP_200_OK)