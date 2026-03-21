import logging
import time

logger = logging.getLogger('middleware')


class RequestLoggingMiddleware:
    """
    Логирует каждый входящий запрос и исходящий ответ:
      - метод, путь, query-строку, IP-адрес, User-Agent
      - статус-код и время выполнения в мс
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start = time.monotonic()

        ip = self._get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '-')
        query = f'?{request.META["QUERY_STRING"]}' if request.META.get('QUERY_STRING') else ''

        logger.info(
            "→ %s %s%s | IP=%s | UA=%s",
            request.method,
            request.path,
            query,
            ip,
            user_agent,
        )

        # Логируем тело запроса (только для небинарных content-type и если небольшое)
        content_type = request.META.get('CONTENT_TYPE', '')
        if request.method in ('POST', 'PUT', 'PATCH') and 'multipart' not in content_type:
            try:
                body = request.body.decode('utf-8', errors='replace')
                if len(body) < 2000:
                    logger.debug("  BODY: %s", body)
                else:
                    logger.debug("  BODY: [%d bytes, truncated]", len(body))
            except Exception:
                logger.debug("  BODY: [не удалось прочитать]")

        response = self.get_response(request)

        elapsed_ms = (time.monotonic() - start) * 1000

        level = logging.INFO
        if response.status_code >= 500:
            level = logging.ERROR
        elif response.status_code >= 400:
            level = logging.WARNING

        logger.log(
            level,
            "← %s %s%s | status=%d | %.1f ms",
            request.method,
            request.path,
            query,
            response.status_code,
            elapsed_ms,
        )

        return response

    @staticmethod
    def _get_client_ip(request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '-')
