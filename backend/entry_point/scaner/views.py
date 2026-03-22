import logging
from datetime import date, timedelta

import redis
from django.conf import settings
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.generics import GenericAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema, OpenApiResponse

from user.models import UserDevice
from .models import QRCode, AccessLog, WeeklyRecord, MonthlyRecord, YearlyRecord
from .serializers import QRCodeResponseSerializer, QRValidateSerializer, QRValidateResponseSerializer

logger = logging.getLogger('scaner')

_redis = redis.Redis(
    host=settings.REDIS_HOST,
    port=settings.REDIS_PORT,
    db=settings.REDIS_DB,
    decode_responses=True,
)


def _finalize_completed_periods(user, today):
    """Каскадная финализация: неделя→месяц, месяц→год. Удаление старых недель."""

    # 1. Завершённые недели → перенос в MonthlyRecord
    completed_weeks = WeeklyRecord.objects.filter(
        user=user, is_finalized=False, week_end__lt=today,
    )
    for week in completed_weeks:
        monthly, _ = MonthlyRecord.objects.get_or_create(
            user=user, year=week.week_start.year, month=week.week_start.month,
        )
        monthly.days_worked += week.days_worked
        monthly.total_seconds += week.total_seconds
        monthly.save(update_fields=['days_worked', 'total_seconds'])

        week.is_finalized = True
        week.save(update_fields=['is_finalized'])
        logger.info(
            "[finalize] Неделя %s–%s → месяц %s-%02d user=%s (+%s дн, +%s сек)",
            week.week_start, week.week_end, monthly.year, monthly.month,
            user.id, week.days_worked, week.total_seconds,
        )

    # 2. Завершённые месяцы → перенос в YearlyRecord
    completed_months = MonthlyRecord.objects.filter(
        user=user, is_finalized=False, end_date__lt=today,
    )
    for monthly in completed_months:
        yearly, _ = YearlyRecord.objects.get_or_create(
            user=user, year=monthly.year,
        )
        yearly.days_worked += monthly.days_worked
        yearly.total_seconds += monthly.total_seconds
        yearly.save(update_fields=['days_worked', 'total_seconds'])

        monthly.is_finalized = True
        monthly.save(update_fields=['is_finalized'])
        logger.info(
            "[finalize] Месяц %s–%s → год %s user=%s (+%s дн, +%s сек)",
            monthly.start_date, monthly.end_date, yearly.year,
            user.id, monthly.days_worked, monthly.total_seconds,
        )

    # 3. Удаление недельных записей старше 1 года
    cutoff = today - timedelta(days=365)
    deleted, _ = WeeklyRecord.objects.filter(user=user, week_start__lt=cutoff).delete()
    if deleted:
        logger.info("[finalize] Удалено %s старых недельных записей user=%s", deleted, user.id)


@extend_schema(
    summary="Валидация QR-кода (эмуляция СКУД)",
    description=(
        "Принимает токен QR-кода, проверяет: не истёк, не использован, "
        "устройство активно. При успехе помечает QR использованным. Доступно админам."
    ),
    request=QRValidateSerializer,
    responses={
        200: OpenApiResponse(description="Доступ разрешён", response=QRValidateResponseSerializer),
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

        # Атомарно помечаем использованным (защита от параллельных запросов)
        updated = QRCode.objects.filter(id=qr.id, is_used=False).update(
            is_used=True, used_at=timezone.now()
        )
        if not updated:
            AccessLog.objects.create(qr_code=qr, result='denied', reason='QR-код уже использован (race)', scanned_by=request.user.email)
            return Response({"detail": "QR-код уже использован"}, status=status.HTTP_403_FORBIDDEN)
        qr.refresh_from_db()

        AccessLog.objects.create(qr_code=qr, result='granted', scanned_by=request.user.email)

        user = qr.device.user
        now = timezone.now()
        today = now.date()
        redis_key = f"attendance:entry:{user.id}"

        entered_at_raw = _redis.get(redis_key)

        if entered_at_raw is None:
            # Первый скан — вход: сохраняем время в Redis (TTL 24 ч)
            _redis.set(redis_key, now.isoformat(), ex=86400)
            attendance_event = 'entry'
            logger.info("[ValidateQRView] Зафиксирован ВХОД: user_id=%s at=%s", user.id, now)

            return Response({
                "result": "granted",
                "attendance_event": attendance_event,
                "entered_at": now.isoformat(),
                "exited_at": None,
                "worked_seconds": None,
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "name": user.name,
                    "surname": user.surname,
                    "patronymic": user.patronymic,
                    "avatar": request.build_absolute_uri(user.avatar.url) if user.avatar else None,
                }
            }, status=status.HTTP_200_OK)

        # Второй скан — выход: вычисляем отработанное время
        from datetime import datetime as dt
        entered_at = timezone.datetime.fromisoformat(entered_at_raw)
        if timezone.is_naive(entered_at):
            entered_at = timezone.make_aware(entered_at)
        worked_delta = now - entered_at
        worked_seconds = max(int(worked_delta.total_seconds()), 0)

        _redis.delete(redis_key)
        attendance_event = 'exit'
        logger.info(
            "[ValidateQRView] Зафиксирован ВЫХОД: user_id=%s at=%s worked=%s сек",
            user.id, now, worked_seconds,
        )

        # --- Обновление недельной записи ---
        week_start = today - timedelta(days=today.weekday())  # понедельник
        weekly, created = WeeklyRecord.objects.get_or_create(
            user=user, week_start=week_start,
        )
        # Считаем день отработанным, если это первый выход за этот день (через Redis-флаг)
        day_key = f"attendance:day:{user.id}:{today.isoformat()}"
        is_new_day = _redis.set(day_key, "1", nx=True, ex=7 * 86400)
        if is_new_day:
            weekly.days_worked += 1
        weekly.total_seconds += worked_seconds
        weekly.save(update_fields=['days_worked', 'total_seconds'])

        # --- Каскадная финализация: завершённые недели→месяц, месяцы→год ---
        _finalize_completed_periods(user, today)

        logger.info("[ValidateQRView] ДОСТУП РАЗРЕШЁН: qr_id=%s user_id=%s email=%s", qr.id, user.id, user.email)

        return Response({
            "result": "granted",
            "attendance_event": attendance_event,
            "entered_at": entered_at.isoformat(),
            "exited_at": now.isoformat(),
            "worked_seconds": worked_seconds,
            "user": {
                "id": user.id,
                "email": user.email,
                "name": user.name,
                "surname": user.surname,
                "patronymic": user.patronymic,
                "avatar": request.build_absolute_uri(user.avatar.url) if user.avatar else None,
            }
        }, status=status.HTTP_200_OK)
