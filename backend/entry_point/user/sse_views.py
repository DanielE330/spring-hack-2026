"""
Server-Sent Events endpoint for real-time attendance notifications.

When an admin scans a user's QR code, an event is published to Redis Pub/Sub.
This SSE endpoint streams those events to the authenticated user in real-time,
allowing the mobile app to immediately refresh the QR code and show a
notification ("Вход зафиксирован" / "Выход зафиксирован").
"""

import json
import logging
import time

import redis
from django.conf import settings
from django.http import StreamingHttpResponse, JsonResponse

from .models import UserDevice

logger = logging.getLogger('user')

_redis_sse = redis.Redis(
    host=settings.REDIS_HOST,
    port=settings.REDIS_PORT,
    db=settings.REDIS_DB,
    decode_responses=True,
)


def _authenticate(request):
    """Extract user from Authorization: Token <device_code> header."""
    auth = request.headers.get('Authorization', '')
    if not auth.startswith('Token '):
        return None
    key = auth[6:].strip()
    if not key:
        return None
    try:
        device = UserDevice.objects.select_related('user').get(key=key, is_active=True)
        return device.user
    except UserDevice.DoesNotExist:
        return None


def user_events_sse(request):
    """
    GET /users/me/events/

    SSE endpoint that streams attendance events for the authenticated user.
    Uses Redis Pub/Sub channel ``user_events:<user_id>``.

    Event format (SSE):
        data: {"event":"qr_scanned","attendance_event":"entry","entered_at":"..."}
    """
    if request.method != 'GET':
        return JsonResponse({'detail': 'Method not allowed'}, status=405)

    user = _authenticate(request)
    if user is None:
        return JsonResponse({'detail': 'Authentication required'}, status=401)

    channel = f'user_events:{user.id}'
    logger.info("[SSE] Client connected: user_id=%s channel=%s", user.id, channel)

    def event_stream():
        pubsub = _redis_sse.pubsub()
        pubsub.subscribe(channel)
        last_heartbeat = time.time()

        # Initial connection event
        yield f'event: connected\ndata: {json.dumps({"user_id": user.id})}\n\n'

        try:
            while True:
                message = pubsub.get_message(timeout=1)
                if message and message['type'] == 'message':
                    data = message['data']
                    logger.info("[SSE] → user_id=%s: %s", user.id, data[:120])
                    yield f'data: {data}\n\n'

                now = time.time()
                if now - last_heartbeat >= 15:
                    yield ': heartbeat\n\n'
                    last_heartbeat = now
        except GeneratorExit:
            logger.info("[SSE] Client disconnected: user_id=%s", user.id)
        finally:
            pubsub.unsubscribe(channel)
            pubsub.close()
            logger.debug("[SSE] Cleaned up pubsub for user_id=%s", user.id)

    response = StreamingHttpResponse(
        event_stream(),
        content_type='text/event-stream',
    )
    response['Cache-Control'] = 'no-cache'
    response['X-Accel-Buffering'] = 'no'
    return response
