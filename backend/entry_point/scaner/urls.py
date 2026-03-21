from django.urls import path
from .views import ValidateQRView

urlpatterns = [
    path('qr/validate/', ValidateQRView.as_view()),   # POST — валидация QR (только admin)
]
