import logging

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView, GenericAPIView, CreateAPIView
from rest_framework.mixins import CreateModelMixin
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema, OpenApiResponse

from .models import GuestPass
from .serializers import (
    GuestPassCreateSerializer,
    GuestPassSerializer,
    GuestPassValidateSerializer,
)
from rest_framework.exceptions import PermissionDenied

logger = logging.getLogger('scaner')


@extend_schema(
    summary="Создать гостевой пропуск",
    description="Создаёт временный пропуск для гостя/подрядчика/курьера. Только администраторы.",
    request=GuestPassCreateSerializer,
    responses={
        201: GuestPassSerializer,
        400: OpenApiResponse(description="Ошибка валидации"),
        403: OpenApiResponse(description="Недостаточно прав"),
    },
    tags=["Guest Passes"],
)
class GuestPassCreateView(CreateModelMixin, GenericAPIView):
    serializer_class = GuestPassCreateSerializer
    queryset = GuestPass.objects.all()
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if not request.user.is_admin:
            return Response(
                {"detail": "Только администраторы могут создавать гостевые пропуска"},
                status=status.HTTP_403_FORBIDDEN,
            )

        return self.create(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        # Возвращаем полный объект через GuestPassSerializer
        output = GuestPassSerializer(serializer.instance).data
        return Response(output, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        guest_pass = serializer.save(created_by=self.request.user)
        logger.info(
            "[GuestPassCreateView] Создан гостевой пропуск id=%s guest=%s by=%s",
            guest_pass.id, guest_pass.guest_name, self.request.user.email,
        )


@extend_schema(
    summary="Список гостевых пропусков",
    description="Возвращает все гостевые пропуска. Только администраторы. "
                "Автоматически помечает истёкшие пропуска.",
    responses={200: GuestPassSerializer(many=True)},
    tags=["Guest Passes"],
)
class GuestPassListView(ListAPIView):
    serializer_class = GuestPassSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Автоматически обновляем статус истёкших пропусков
        now = timezone.now()
        GuestPass.objects.filter(
            status='active', valid_until__lt=now,
        ).update(status='expired')

        return GuestPass.objects.all().select_related('created_by')

    def list(self, request, *args, **kwargs):
        if not request.user.is_admin:
            return Response(
                {"detail": "Только администраторы могут просматривать гостевые пропуска"},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().list(request, *args, **kwargs)


@extend_schema(
    summary="Отменить гостевой пропуск",
    description="Отменяет (revoke) гостевой пропуск по ID. Только администраторы.",
    responses={
        200: GuestPassSerializer,
        404: OpenApiResponse(description="Пропуск не найден"),
        403: OpenApiResponse(description="Недостаточно прав"),
    },
    tags=["Guest Passes"],
)
class GuestPassRevokeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        if not request.user.is_admin:
            return Response(
                {"detail": "Только администраторы могут отменять пропуска"},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            guest_pass = GuestPass.objects.select_related('created_by').get(pk=pk)
        except GuestPass.DoesNotExist:
            return Response({"detail": "Пропуск не найден"}, status=status.HTTP_404_NOT_FOUND)

        if guest_pass.status != 'active':
            return Response(
                {"detail": f"Пропуск нельзя отменить — текущий статус: {guest_pass.status}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        guest_pass.revoke()
        logger.info(
            "[GuestPassRevokeView] Пропуск id=%s отменён администратором %s",
            guest_pass.id, request.user.email,
        )
        return Response(GuestPassSerializer(guest_pass).data)


@extend_schema(
    summary="Валидация гостевого пропуска",
    description="Проверяет токен гостевого пропуска при сканировании. "
                "При успехе помечает как использованный.",
    request=GuestPassValidateSerializer,
    responses={
        200: OpenApiResponse(description="Доступ разрешён"),
        403: OpenApiResponse(description="Доступ запрещён"),
        404: OpenApiResponse(description="Пропуск не найден"),
    },
    tags=["Guest Passes"],
)
class GuestPassValidateView(GenericAPIView):
    serializer_class = GuestPassValidateSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if not request.user.is_admin:
            return Response(
                {"detail": "Только администраторы могут валидировать пропуска"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data['token']

        try:
            guest_pass = GuestPass.objects.select_related('created_by').get(token=token)
        except GuestPass.DoesNotExist:
            return Response({"detail": "Гостевой пропуск не найден"}, status=status.HTTP_404_NOT_FOUND)

        if not guest_pass.is_valid:
            reason = 'expired' if guest_pass.is_expired else guest_pass.status
            logger.warning(
                "[GuestPassValidateView] Доступ запрещён: id=%s reason=%s",
                guest_pass.id, reason,
            )
            return Response(
                {"result": "denied", "reason": reason, "guest_name": guest_pass.guest_name},
                status=status.HTTP_403_FORBIDDEN,
            )

        guest_pass.mark_used()
        logger.info(
            "[GuestPassValidateView] Доступ разрешён: id=%s guest=%s",
            guest_pass.id, guest_pass.guest_name,
        )
        return Response({
            "result": "granted",
            "guest_name": guest_pass.guest_name,
            "guest_company": guest_pass.guest_company,
            "purpose": guest_pass.purpose,
            "valid_until": guest_pass.valid_until.isoformat(),
        })
