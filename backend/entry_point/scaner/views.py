import logging

from django.utils import timezone
from rest_framework.generics import GenericAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema, OpenApiResponse

from .models import QRCode, AccessLog, AttendanceRecord
from .serializers import QRValidateSerializer

logger = logging.getLogger('scaner')


@extend_schema(
    summary="Валидация QR-кода (эмуляция СКУД)",
    description=(
        "Принимает токен QR-кода, проверяет: не истёк, не использован, "
        "устройство активно. При успехе помечает QR использованным. Доступно админам."
    ),
    request=QRValidateSerializer,
    responses={
        200: OpenApiResponse(description="Доступ разрешён"),
        403: OpenApiResponse(description="Доступ запрещён"),
        404: OpenApiResponse(description="QR-код не найден"),
    },
    tags=["QR"]
)
class ValidateQRView(GenericAPIView):
    serializer_class = QRValidateSerializer
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if not request.user.is_admin:
            return Response({"detail": "Только администраторы могут валидировать QR"}, status=status.HTTP_403_FORBIDDEN)

        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        token = serializer.validated_data['token']
        logger.info("[ValidateQRView] token=%s... admin_id=%s", token[:12], request.user.id)

        try:
            qr = QRCode.objects.select_related('device__user').get(token=token)
        except QRCode.DoesNotExist:
            logger.warning("[ValidateQRView] QR не найден: token=%s...", token[:12])
            AccessLog.objects.create(qr_code=None, result='denied', reason='QR-код не найден', scanned_by=request.user.email)
            return Response({"detail": "QR-код не найден"}, status=status.HTTP_404_NOT_FOUND)

        deny_reason = None
        if qr.is_used:
            deny_reason = "QR-код уже использован"
        elif timezone.now() >= qr.expires_at:
            deny_reason = "QR-код истёк"

        if deny_reason:
            logger.warning("[ValidateQRView] Отказ: %s qr_id=%s", deny_reason, qr.id)
            AccessLog.objects.create(qr_code=qr, result='denied', reason=deny_reason, scanned_by=request.user.email)
            return Response({"detail": deny_reason}, status=status.HTTP_403_FORBIDDEN)

        # Атомарно помечаем использованным
        qr.is_used = True
        qr.used_at = timezone.now()
        qr.save(update_fields=['is_used', 'used_at'])

        AccessLog.objects.create(qr_code=qr, result='granted', scanned_by=request.user.email)

        user = qr.device.user
        now = timezone.now()
        today = now.date()

        # Учёт посещаемости: первый скан = вход, второй (если уже есть вход) = выход
        record, created = AttendanceRecord.objects.get_or_create(
            user=user,
            date=today,
            defaults={'entered_at': now},
        )
        if not created and record.exited_at is None:
            # Уже есть запись входа — фиксируем выход
            record.exited_at = now
            record.save(update_fields=['exited_at'])
            attendance_event = 'exit'
            logger.info("[ValidateQRView] Зафиксирован ВЫХОД: user_id=%s at=%s", user.id, now)
        elif not created and record.exited_at is not None:
            # Повторное посещение: сбрасываем (новый вход поверх завершённой записи)
            record.entered_at = now
            record.exited_at = None
            record.save(update_fields=['entered_at', 'exited_at'])
            attendance_event = 'entry'
            logger.info("[ValidateQRView] Зафиксирован повторный ВХОД: user_id=%s at=%s", user.id, now)
        else:
            attendance_event = 'entry'
            logger.info("[ValidateQRView] Зафиксирован ВХОД: user_id=%s at=%s", user.id, now)

        logger.info("[ValidateQRView] ДОСТУП РАЗРЕШЁН: qr_id=%s user_id=%s email=%s", qr.id, user.id, user.email)

        return Response({
            "result": "granted",
            "attendance_event": attendance_event,
            "entered_at": record.entered_at,
            "exited_at": record.exited_at,
            "user": {
                "id": user.id,
                "email": user.email,
                "name": user.name,
                "surname": user.surname,
                "patronymic": user.patronymic,
            }
        }, status=status.HTTP_200_OK)
