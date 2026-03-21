import logging
import uuid

from django.db import models
from django.utils import timezone
from datetime import timedelta

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
