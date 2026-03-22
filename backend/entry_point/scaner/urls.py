from django.urls import path
from .views import ValidateQRView
from .export_views import ExportAttendanceExcelView
from .guest_views import (
    GuestPassCreateView,
    GuestPassListView,
    GuestPassRevokeView,
    GuestPassValidateView,
)

urlpatterns = [
    # qr/generate/ определён в user.urls (user.qr_views.GenerateQRView)
    path('qr/validate/', ValidateQRView.as_view()),    # POST — валидация QR (только admin)
    path('reports/attendance/', ExportAttendanceExcelView.as_view()),  # GET — Excel-отчёт

    # Гостевые пропуска
    path('guest-passes/', GuestPassListView.as_view()),              # GET  — список
    path('guest-passes/create/', GuestPassCreateView.as_view()),     # POST — создать
    path('guest-passes/<int:pk>/revoke/', GuestPassRevokeView.as_view()),  # POST — отменить
    path('guest-passes/validate/', GuestPassValidateView.as_view()), # POST — валидация при сканировании
]
