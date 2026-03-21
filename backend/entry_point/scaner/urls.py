from django.urls import path
from .views import GenerateQRView, ValidateQRView
from .export_views import ExportAttendanceExcelView

urlpatterns = [
    path('qr/generate/', GenerateQRView.as_view()),    # POST — генерация QR
    path('qr/validate/', ValidateQRView.as_view()),    # POST — валидация QR (только admin)
    path('reports/attendance/', ExportAttendanceExcelView.as_view()),  # GET — Excel-отчёт
]
