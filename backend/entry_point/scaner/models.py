import calendar
import logging
import uuid
from datetime import date, timedelta

from django.db import models
from django.utils import timezone

from user.models import UserDevice

logger = logging.getLogger('scaner')

QR_TTL_MINUTES = 5


class QRCode(models.Model):
    device = models.ForeignKey(
        UserDevice, on_delete=models.CASCADE, related_name='qr_codes'
    )
    token = models.CharField(max_length=64, unique=True, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(editable=False)
    used_at = models.DateTimeField(null=True, blank=True)
    is_used = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        if not self.token:
            self.token = uuid.uuid4().hex
        if not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=QR_TTL_MINUTES)
        super().save(*args, **kwargs)
        if is_new:
            logger.info(
                "[QRCode.save] Создан QR: id=%s device_id=%s expires_at=%s",
                self.id, self.device_id, self.expires_at
            )

    @property
    def is_valid(self):
        """True — если не использован, не истёк и устройство активно."""
        return (
            not self.is_used
            and timezone.now() < self.expires_at
            and self.device.is_active
        )

    def __str__(self):
        return f"QR {self.token[:12]}... device={self.device_id} used={self.is_used}"


class WeeklyRecord(models.Model):
    """Учёт рабочего времени за неделю (пн–вс).
    Создаётся при первом выходе в эту неделю, накапливает данные.
    По окончании недели is_finalized=True и данные переносятся в MonthlyRecord.
    Удаляется автоматически через год.
    """
    user = models.ForeignKey(
        'user.User', on_delete=models.CASCADE, related_name='weekly_records'
    )
    week_start = models.DateField(help_text="Понедельник начала недели")
    week_end = models.DateField(null=True, blank=True, help_text="Воскресенье конца недели")
    days_worked = models.PositiveIntegerField(default=0)
    total_seconds = models.PositiveBigIntegerField(default=0, help_text="Общее время работы за неделю (секунды)")
    is_finalized = models.BooleanField(default=False, help_text="Данные перенесены в месяц")

    class Meta:
        unique_together = ('user', 'week_start')
        ordering = ['-week_start']

    def save(self, *args, **kwargs):
        if not self.week_end:
            self.week_end = self.week_start + timedelta(days=6)
        super().save(*args, **kwargs)

    @property
    def total_hours(self):
        return round(self.total_seconds / 3600, 2)

    def __str__(self):
        return f"Week {self.week_start}–{self.week_end} user={self.user_id} days={self.days_worked} hrs={self.total_hours}"


class MonthlyRecord(models.Model):
    """Учёт рабочего времени за месяц.
    Создаётся по окончании недели (при финализации WeeklyRecord).
    По окончании месяца is_finalized=True и данные переносятся в YearlyRecord.
    """
    user = models.ForeignKey(
        'user.User', on_delete=models.CASCADE, related_name='monthly_records'
    )
    year = models.PositiveIntegerField()
    month = models.PositiveSmallIntegerField()
    start_date = models.DateField(null=True, blank=True, help_text="Первое число месяца")
    end_date = models.DateField(null=True, blank=True, help_text="Последнее число месяца")
    days_worked = models.PositiveIntegerField(default=0)
    total_seconds = models.PositiveBigIntegerField(default=0, help_text="Общее время работы за месяц (секунды)")
    is_finalized = models.BooleanField(default=False, help_text="Данные перенесены в год")

    class Meta:
        unique_together = ('user', 'year', 'month')
        ordering = ['-year', '-month']

    def save(self, *args, **kwargs):
        if not self.start_date:
            self.start_date = date(self.year, self.month, 1)
        if not self.end_date:
            last_day = calendar.monthrange(self.year, self.month)[1]
            self.end_date = date(self.year, self.month, last_day)
        super().save(*args, **kwargs)

    @property
    def total_hours(self):
        return round(self.total_seconds / 3600, 2)

    def __str__(self):
        return f"{self.start_date}–{self.end_date} user={self.user_id} days={self.days_worked} hrs={self.total_hours}"


class YearlyRecord(models.Model):
    """Учёт рабочего времени за год.
    Создаётся по окончании месяца (при финализации MonthlyRecord).
    """
    user = models.ForeignKey(
        'user.User', on_delete=models.CASCADE, related_name='yearly_records'
    )
    year = models.PositiveIntegerField()
    start_date = models.DateField(null=True, blank=True, help_text="1 января")
    end_date = models.DateField(null=True, blank=True, help_text="31 декабря")
    days_worked = models.PositiveIntegerField(default=0)
    total_seconds = models.PositiveBigIntegerField(default=0, help_text="Общее время работы за год (секунды)")

    class Meta:
        unique_together = ('user', 'year')
        ordering = ['-year']

    def save(self, *args, **kwargs):
        if not self.start_date:
            self.start_date = date(self.year, 1, 1)
        if not self.end_date:
            self.end_date = date(self.year, 12, 31)
        super().save(*args, **kwargs)

    @property
    def total_hours(self):
        return round(self.total_seconds / 3600, 2)

    def __str__(self):
        return f"{self.start_date}–{self.end_date} user={self.user_id} days={self.days_worked} hrs={self.total_hours}"


class AccessLog(models.Model):
    RESULT_CHOICES = [
        ('granted', 'Пропущен'),
        ('denied', 'Отклонён'),
    ]

    qr_code = models.ForeignKey(
        QRCode, on_delete=models.SET_NULL, null=True, related_name='logs'
    )
    scanned_at = models.DateTimeField(auto_now_add=True)
    result = models.CharField(max_length=10, choices=RESULT_CHOICES)
    reason = models.CharField(max_length=255, null=True, blank=True)
    scanned_by = models.CharField(
        max_length=100, null=True, blank=True,
        help_text="email админа / IP сканера"
    )

    def __str__(self):
        return f"AccessLog [{self.result}] at {self.scanned_at}"
