from django.urls import path
from .views import ValidateQRView
from .export_views import ExportAttendanceExcelView
from .guest_views import (
    GuestPassListCreateView,
    GuestPassRevokeView,
    GuestPassValidateView,
)

urlpatterns = [
    # qr/generate/ определён в user.urls (user.qr_views.GenerateQRView)
    path('qr/validate/', ValidateQRView.as_view()),    # POST — валидация QR (только admin)
    path('reports/attendance/', ExportAttendanceExcelView.as_view()),  # GET — Excel-отчёт

    # Гостевые пропуска
    path('guest-passes/', GuestPassListCreateView.as_view()),         # GET/POST — список и создание
    path('guest-passes/create/', GuestPassListCreateView.as_view()),  # POST — создание (альтернативный путь)
    path('guest-passes/<int:pk>/revoke/', GuestPassRevokeView.as_view()),  # POST — отменить
    path('guest-passes/validate/', GuestPassValidateView.as_view()), # POST — валидация при сканировании
]
