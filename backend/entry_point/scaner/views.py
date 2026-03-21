import logging

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.generics import GenericAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema, OpenApiResponse

from user.models import UserDevice
from .models import QRCode, AccessLog, AttendanceRecord
from .serializers import QRCodeResponseSerializer, QRValidateSerializer

logger = logging.getLogger('scaner')


@extend_schema(
    summary="Генерация QR-кода",
    description=(
        "Создаёт одноразовый QR-код с TTL 5 минут для текущего устройства "
        "(определяется по Authorization: Token <device_code>). "
        "Тело запроса не требуется. "
        "Если у устройства уже есть активный неиспользованный QR — возвращает его. "
        "Передайте ?force_new=1 чтобы принудительно создать новый."
    ),
    request=None,
    responses={
        200: OpenApiResponse(description="QR-код", response=QRCodeResponseSerializer),
        401: OpenApiResponse(description="Не авторизован / устройство не найдено"),
    },
    tags=["QR"]
)
class GenerateQRView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        device = getattr(request, 'auth', None)

        if not isinstance(device, UserDevice):
            logger.warning("[GenerateQRView] request.auth не является UserDevice, user_id=%s", request.user.id)
            return Response({"detail": "Устройство не определено. Авторизуйтесь заново."},
                            status=status.HTTP_401_UNAUTHORIZED)

        logger.info("[GenerateQRView] user_id=%s device_id=%s", request.user.id, device.id)

        force_new = request.query_params.get('force_new') in ('1', 'true')

        if not force_new:
            # Ищем активный QR (ещё не использован, не истёк)
            existing_qr = QRCode.objects.filter(
                device=device, is_used=False, expires_at__gt=timezone.now()
            ).order_by('-created_at').first()

            if existing_qr:
                logger.debug("[GenerateQRView] Возвращаем существующий QR id=%s", existing_qr.id)
                return Response(QRCodeResponseSerializer(existing_qr).data, status=status.HTTP_200_OK)

        qr = QRCode.objects.create(device=device)
        logger.info("[GenerateQRView] Создан новый QR id=%s expires_at=%s", qr.id, qr.expires_at)

        return Response(QRCodeResponseSerializer(qr).data, status=status.HTTP_200_OK)


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
