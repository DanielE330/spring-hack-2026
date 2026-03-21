from django.http import HttpResponse, Http404
from django.conf import settings
from pathlib import Path
import mimetypes


def serve_password_reset(request, resource: str = None):
    """Serve files from <BASE_DIR>/frontend/password_reset/.

    If `resource` is empty or looks like a page (e.g. 'confirm'), serve index.html.
    """
    base = Path(settings.BASE_DIR) / 'frontend' / 'password_reset'
    if not base.exists():
        raise Http404('Password reset frontend not found')

    # Normalize resource
    if not resource or resource in ('', 'confirm', 'index.html'):
        target = base / 'index.html'
    else:
        # Prevent path traversal
        target = (base / resource).resolve()
        if not str(target).startswith(str(base.resolve())):
            raise Http404('Invalid path')

    if not target.exists() or not target.is_file():
        raise Http404('Not found')

    # Guess content type
    content_type, _ = mimetypes.guess_type(str(target))
    content = target.read_bytes()
    return HttpResponse(content, content_type=content_type or 'application/octet-stream')
