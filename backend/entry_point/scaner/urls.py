from django.urls import path
from .views import ValidateQRView
from .export_views import ExportAttendanceExcelView

urlpatterns = [
    # qr/generate/ определён в user.urls (user.qr_views.GenerateQRView)
    path('qr/validate/', ValidateQRView.as_view()),    # POST — валидация QR (только admin)
    path('reports/attendance/', ExportAttendanceExcelView.as_view()),  # GET — Excel-отчёт
]
