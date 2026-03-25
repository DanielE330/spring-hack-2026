# API Документация

## Базовый URL

```
http://localhost:8000/api
```

## Аутентификация

Все endpoints (кроме публичных) требуют заголовок:

```
Authorization: Bearer <access_token>
```

## Формат ответа

Успешный ответ (200, 201):
```json
{
  "success": true,
  "data": { ... }
}
```

Ошибка (4xx, 5xx):
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Описание ошибки"
  }
}
```

## API Endpoints

### 🔐 Аутентификация

#### POST /auth/first-admin/
Создание первого администратора (только если БД пуста)

**Request:**
```json
{
  "email": "admin@example.com",
  "name": "Admin",
  "surname": "User",
  "patronymic": "Patronymic",
  "password": "SecurePassword123"
}
```

**Response:** 201
```json
{
  "message": "Первый админ создан",
  "email": "admin@example.com"
}
```

#### POST /auth/login/
Вход в систему

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "device_name": "iPhone 15"
}
```

**Response:** 200
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John",
  "is_admin": false,
  "device_code": "abc123xyz",
  "user_type": "regular"
}
```

#### POST /auth/logout/
Выход из системы

**Request:**
```json
{
  "device_code": "abc123xyz"
}
```

#### POST /auth/password-reset/
Запрос на сброс пароля

**Request:**
```json
{
  "email": "user@example.com"
}
```

#### POST /auth/password-reset/confirm/
Подтверждение сброса пароля

**Request:**
```json
{
  "token": "reset_token_here",
  "new_password": "NewPassword123"
}
```

### 👤 Пользователи

#### GET /users/me/
Получить профиль текущего пользователя

**Response:** 200
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John",
  "surname": "Doe",
  "is_admin": false,
  "avatar": "http://...",
  "user_type": "regular"
}
```

#### POST /auth/create-user/
Создать нового пользователя (только для admin)

**Request:**
```json
{
  "email": "newuser@example.com",
  "name": "Jane",
  "surname": "Smith",
  "password": "SecurePassword123",
  "is_admin": false
}
```

#### POST /users/me/avatar/
Загрузить аватар (multipart/form-data)

**Request:**
```
Form Data:
  avatar: <image_file>
```

**Response:** 200
```json
{
  "avatar": "http://localhost:8000/media/avatars/user_1.jpg"
}
```

#### GET /users/me/devices/
Получить список устройств текущего пользователя

**Response:** 200
```json
[
  {
    "id": 1,
    "device_name": "iPhone 15",
    "ip_address": "192.168.1.100",
    "is_active": true,
    "last_used": "2026-03-25T10:30:00Z",
    "is_current": true
  }
]
```

#### POST /users/me/devices/<device_id>/revoke/
Деактивировать устройство

**Response:** 200
```json
{
  "message": "Устройство деактивировано"
}
```

### 🎫 QR-коды

#### POST /qr/generate/
Сгенерировать QR-код для текущего пользователя

**Response:** 200
```json
{
  "qr_code": "data:image/png;base64,...",
  "token": "qr_token_123",
  "expires_at": "2026-03-25T11:00:00Z"
}
```

#### POST /qr/validate/
Валидировать QR-код при входе/выходе (только для admin)

**Request:**
```json
{
  "token": "qr_token_123"
}
```

**Response:** 200
```json
{
  "status": "success",
  "user_id": 1,
  "user_name": "John Doe",
  "timestamp": "2026-03-25T10:30:00Z",
  "entry_type": "entry"
}
```

### 👥 Гостевые пропуска

#### GET /guest-passes/
Получить список гостевых пропусков

**Query Parameters:**
- `status`: pending, active, revoked
- `page`: номер страницы
- `limit`: количество на странице

**Response:** 200
```json
{
  "results": [
    {
      "id": 1,
      "guest_email": "guest@example.com",
      "guest_name": "John",
      "guest_company": "ABC Corp",
      "purpose": "meeting",
      "valid_from": "2026-03-25T09:00:00Z",
      "valid_until": "2026-03-25T17:00:00Z",
      "is_revoked": false,
      "created_by": 1
    }
  ],
  "count": 1,
  "next": null
}
```

#### POST /guest-passes/
Создать гостевой пропуск (только для admin)

**Request:**
```json
{
  "guest_email": "guest@example.com",
  "guest_name": "John",
  "guest_surname": "Smith",
  "guest_patronymic": "Patronymic",
  "guest_company": "ABC Corp",
  "purpose": "meeting",
  "note": "Встреча с менеджером",
  "valid_from": "2026-03-25T09:00:00Z",
  "valid_until": "2026-03-25T17:00:00Z",
  "guest_password": "GuestPass123"
}
```

**Response:** 201
```json
{
  "id": 1,
  "guest_email": "guest@example.com",
  "qr_code": "data:image/png;base64,...",
  "message": "Гостевой пропуск создан"
}
```

#### POST /guest-passes/<id>/revoke/
Отменить гостевой пропуск (только для admin)

**Response:** 200
```json
{
  "message": "Гостевой пропуск отменён"
}
```

#### POST /guest-passes/validate/
Валидировать гостевой пропуск

**Request:**
```json
{
  "token": "guest_token_123"
}
```

### 📊 Отчеты

#### GET /reports/attendance/
Получить отчет о посещаемости (Excel)

**Query Parameters:**
- `from_date`: дата начала (2026-03-01)
- `to_date`: дата окончания (2026-03-31)
- `user_id`: ID пользователя (опционально)

**Response:** 200 (файл Excel)

## Коды ошибок

| Код | Описание |
|-----|---------|
| 400 | Неверные параметры запроса |
| 401 | Не авторизован |
| 403 | Доступ запрещен |
| 404 | Ресурс не найден |
| 409 | Конфликт (например, пользователь уже существует) |
| 500 | Внутренняя ошибка сервера |

## Примеры запросов

### cURL

```bash
# Вход
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password"
  }'

# Получить профиль (с токеном)
curl -X GET http://localhost:8000/api/users/me/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Python (requests)

```python
import requests

# Вход
response = requests.post('http://localhost:8000/api/auth/login', json={
    'email': 'admin@example.com',
    'password': 'password'
})
token = response.json()['device_code']

# Получить профиль
headers = {'Authorization': f'Bearer {token}'}
response = requests.get('http://localhost:8000/api/users/me/', headers=headers)
print(response.json())
```

### JavaScript (fetch)

```javascript
// Вход
const response = await fetch('http://localhost:8000/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'admin@example.com',
    password: 'password'
  })
});
const { device_code } = await response.json();

// Получить профиль
const meResponse = await fetch('http://localhost:8000/api/users/me/', {
  headers: { 'Authorization': `Bearer ${device_code}` }
});
const user = await meResponse.json();
console.log(user);
```

## Swagger/OpenAPI

Полная интерактивная документация доступна по адресу:
- Swagger UI: http://localhost:8000/schema/swagger/
- ReDoc: http://localhost:8000/schema/redoc/

---

Последнее обновление: 25 марта 2026 г.
