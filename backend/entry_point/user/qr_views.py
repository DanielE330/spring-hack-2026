import logging

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema, OpenApiResponse

from .models import UserDevice
from scaner.models import QRCode
from scaner.serializers import QRCodeResponseSerializer

logger = logging.getLogger('user')


@extend_schema(
    summary="Генерация QR-кода",
    description=(
        "Создаёт одноразовый QR-код с TTL 5 минут для текущего устройства "
        "(определяется по Authorization: Token <device_code>). "
        "Тело запроса не требуется. "
        "Если у устройства уже есть активный неиспользованный QR — возвращает его. "
        "Query-параметр ?force_new=1 деактивирует все старые QR и создаёт новый."
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

        force_new = (
            request.query_params.get('force_new') == '1'
            or request.data.get('force_new') in (True, '1', 1, 'true')
        )
        logger.info("[GenerateQRView] user_id=%s device_id=%s force_new=%s", request.user.id, device.id, force_new)

        if force_new:
            # Деактивируем все активные QR-коды этого устройства
            invalidated = QRCode.objects.filter(
                device=device, is_used=False, expires_at__gt=timezone.now()
            ).update(is_used=True, used_at=timezone.now())
            logger.info("[GenerateQRView] Деактивировано %d старых QR для device_id=%s", invalidated, device.id)
            qr = QRCode.objects.create(device=device)
            logger.info("[GenerateQRView] Создан новый QR (force) id=%s expires_at=%s", qr.id, qr.expires_at)
        else:
            existing_qr = QRCode.objects.filter(
                device=device, is_used=False, expires_at__gt=timezone.now()
            ).order_by('-created_at').first()

            if existing_qr:
                logger.debug("[GenerateQRView] Возвращаем существующий QR id=%s", existing_qr.id)
                qr = existing_qr
            else:
                qr = QRCode.objects.create(device=device)
                logger.info("[GenerateQRView] Создан новый QR id=%s expires_at=%s", qr.id, qr.expires_at)

        return Response(QRCodeResponseSerializer(qr).data, status=status.HTTP_200_OK)
