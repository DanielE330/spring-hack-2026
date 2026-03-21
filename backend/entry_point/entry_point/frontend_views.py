from django.http import HttpResponse, Http404
from django.conf import settings
from pathlib import Path


def serve_password_reset(request):
    """Serve the static password-reset frontend index.html so links to the backend work.

    Looks for file at <BASE_DIR>/frontend/password_reset/index.html
    """
    path = Path(settings.BASE_DIR) / 'frontend' / 'password_reset' / 'index.html'
    if not path.exists():
        raise Http404("Password reset frontend not found")

    content = path.read_text(encoding='utf-8')
    return HttpResponse(content, content_type='text/html')
