from django.urls import path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from .views import (
    FirstAdminView, CreateUserView, LoginView,
    MeView, LogoutView,
    DeviceListView, DeviceDeleteView, AdminDeviceDeleteView,
    PasswordResetRequestView, PasswordResetConfirmView,
    AvatarUpdateView,
)
from .qr_views import GenerateQRView
from .sse_views import user_events_sse

urlpatterns = [
    # Swagger документация
    path('schema/', SpectacularAPIView.as_view()),
    path('docs/', SpectacularSwaggerView.as_view(url='/schema/')),

    # Auth
    path('auth/first-admin/', FirstAdminView.as_view()),
    path('auth/create-user/', CreateUserView.as_view()),
    path('auth/login/', LoginView.as_view()),
    path('auth/logout/', LogoutView.as_view()),
    path('auth/password-reset/', PasswordResetRequestView.as_view()),          # POST — запрос сброса пароля
    path('auth/password-reset/confirm/', PasswordResetConfirmView.as_view()),  # POST — подтверждение сброса

    # User
    path('users/me/', MeView.as_view()),                         # GET  — данные текущего пользователя
    path('users/me/avatar/', AvatarUpdateView.as_view()),        # PUT/DELETE — аватарка
    path('users/me/events/', user_events_sse),                   # GET  — SSE real-time events
    path('users/me/devices/', DeviceListView.as_view()),         # GET  — список активных сессий
    path('users/me/devices/<int:device_id>/', DeviceDeleteView.as_view()),   # DELETE — завершить свою сессию

    # Admin
    path('admin/devices/<int:device_id>/', AdminDeviceDeleteView.as_view()),  # DELETE — принудительно завершить любую

    # QR
    path('qr/generate/', GenerateQRView.as_view()),  # POST — генерация QR-кода
]