from django.urls import path
from .views import GenerateQRView, ValidateQRView

urlpatterns = [
    path('qr/generate/', GenerateQRView.as_view()),   # POST — генерация QR (Authorization header)
    path('qr/validate/', ValidateQRView.as_view()),   # POST — валидация QR (только admin)
]
