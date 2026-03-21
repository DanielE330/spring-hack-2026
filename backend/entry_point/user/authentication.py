import logging

from django.utils import timezone
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

from .models import UserDevice

logger = logging.getLogger('user')


class DeviceCodeAuthentication(BaseAuthentication):
    """
    Аутентификация по заголовку:  Authorization: Token <device_code>
    Устройство должно существовать и быть активным.
    При каждом успешном запросе обновляет last_used.
    """
    keyword = 'Token'

    def authenticate(self, request):
        auth_header = request.headers.get('Authorization', '')

        if not auth_header.startswith(f'{self.keyword} '):
            return None  # пропускаем — пусть другой backend попробует

        device_code = auth_header[len(self.keyword) + 1:].strip()
        if not device_code:
            return None

        try:
            device = UserDevice.objects.select_related('user').get(key=device_code)
        except UserDevice.DoesNotExist:
            logger.warning("[DeviceCodeAuth] Устройство не найдено: code=%s…", device_code[:12])
            raise AuthenticationFailed('Недействительный ключ устройства')

        if not device.is_active:
            logger.warning("[DeviceCodeAuth] Устройство деактивировано: id=%s", device.id)
            raise AuthenticationFailed('Сессия на этом устройстве завершена. Войдите снова.')

        # Обновляем время последнего использования
        device.last_used = timezone.now()
        device.save(update_fields=['last_used'])

        logger.debug(
            "[DeviceCodeAuth] OK user_id=%s device_id=%s",
            device.user_id, device.id,
        )
        return (device.user, device)

    def authenticate_header(self, request):
        return self.keyword
