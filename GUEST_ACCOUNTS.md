# 👤 Управление гостевыми аккаунтами — Подробное руководство

## Обзор

Администратор может создавать временные аккаунты для гостей, подрядчиков и временных сотрудников. Каждый гостевой аккаунт имеет:
- **Email и пароль** для входа в приложение
- **QR-код пропуск** для регистрации входа/выхода
- **Дату истечения** — автоматическое отключение доступа
- **Профиль** — отмечен как "Временный гость"

---

## 🚀 Быстрый старт

### Шаг 1: Создание гостевого аккаунта через API

**Администратор создаёт гостевой пропуск с аккаунтом:**

```bash
# Получить токен администратора
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }' | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

# Создать гостевой пропуск с аккаунтом
curl -X POST http://localhost:8000/guest-passes/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "guest_name": "Иван Петров",
    "guest_company": "ABC Corporation",
    "purpose": "temp_employee",
    "note": "Временный инженер на месяц",
    "guest_email": "ivan.petrov@abc.com",
    "guest_password": "SecurePass123",
    "valid_from": "2026-03-25T09:00:00Z",
    "valid_until": "2026-04-25T18:00:00Z"
  }'
```

**Ответ:**
```json
{
  "id": 1,
  "guest_name": "Иван Петров",
  "guest_company": "ABC Corporation",
  "purpose": "temp_employee",
  "token": "a1b2c3d4e5f6...",
  "status": "active",
  "user_email": "ivan.petrov@abc.com",
  "has_account": true,
  "valid_from": "2026-03-25T09:00:00Z",
  "valid_until": "2026-04-25T18:00:00Z",
  "is_valid": true,
  "is_expired": false
}
```

---

## 🔐 Гость входит в свой аккаунт

### Шаг 2: Вход гостя в приложение

Гость использует полученный **email и пароль**:

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ivan.petrov@abc.com",
    "password": "SecurePass123",
    "device_name": "iPhone 15"
  }'
```

**Ответ:**
```json
{
  "id": 42,
  "email": "ivan.petrov@abc.com",
  "name": "Петров",
  "surname": "Иван",
  "is_admin": false,
  "user_type": "guest",
  "user_type_display": "Временный гость",
  "guest_valid_until": "2026-04-25T18:00:00Z",
  "device_code": "xyz789...",
  "avatar": null
}
```

**⚠️ Если пропуск истёк:**
```json
{
  "detail": "Ваш гостевой пропуск истёк"
}
```

---

## 👁️ Профиль гостя

### Шаг 3: Просмотр профиля

```bash
curl -X GET http://localhost:8000/auth/profile \
  -H "Authorization: Bearer $GUEST_TOKEN"
```

**Ответ:**
```json
{
  "id": 42,
  "email": "ivan.petrov@abc.com",
  "name": "Петров",
  "surname": "Иван",
  "patronymic": null,
  "is_admin": false,
  "avatar": null,
  "user_type": "guest",
  "user_type_display": "Временный гость",
  "guest_valid_until": "2026-04-25T18:00:00Z",
  "is_guest": true
}
```

**Поля описание:**
- `user_type: "guest"` — это временный гость
- `user_type_display: "Временный гость"` — читаемое название
- `guest_valid_until: "2026-04-25T18:00:00Z"` — дата истечения доступа
- `is_guest: true` — проверка что это гость и время ещё не истекло

---

## 📱 QR-код и сканирование

### Шаг 4: Сканирование QR-кода при входе

Гость может сканировать QR-код пропуска при входе:

```bash
# Генерировать QR-код
curl -X POST http://localhost:8000/generate-qr \
  -H "Authorization: Bearer $GUEST_TOKEN"

# Результат: генерируется уникальный QR-код с TTL 5 минут
```

Другой сотрудник сканирует этот QR:

```bash
curl -X POST http://localhost:8000/validate-qr \
  -H "Authorization: Bearer $SCANNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "qr_code_value"}'
```

---

## 🛠️ Управление через админ-панель Django

### Доступ к админ-панели

Откройте http://localhost:8000/django-admin/ и войдите как администратор.

### Просмотр гостевых пропусков

**Users** → Выберите пользователя:
- `user_type: guest` — типированный гостевой аккаунт
- `guest_valid_until` — дата истечения
- Таблица показывает статус гостя (✅ Активен / ❌ Истёк)

**Guest Passes**:
- Список всех гостевых пропусков
- Столбец `Email аккаунта` показывает связанный email
- Возможность отменить пропуск (revoke)

### Создание гостевого пропуска через админ-панель

1. **Guest Passes** → **Add Guest Pass**
2. Заполните поля:
   - **Guest name**: "Иван Петров"
   - **Guest company**: "ABC Corp"
   - **Purpose**: "Временный сотрудник"
   - **Note**: комментарий (опционально)
   - **Valid from/until**: даты
   - **User**: (опционально, для связи с существующим пользователем)
3. **Save**

---

## 📊 Типы пропусков (Purpose)

| Значение | Описание |
|----------|---------|
| `meeting` | Встреча |
| `contractor` | Подрядчик |
| `delivery` | Доставка/Курьер |
| `temp_employee` | **Временный сотрудник** (с аккаунтом) |
| `other` | Другое |

---

## ⌚ Жизненный цикл гостевого аккаунта

```
1. Администратор создаёт гостевой пропуск с email/пароль
                    ↓
2. Система создаёт User (user_type='guest')
                    ↓
3. Гость входит в приложение (email + пароль)
                    ↓
4. Проверяются даты действия пропуска
                    ↓
        ✅ В срок → доступ предоставлен
        ❌ Истёк   → доступ заблокирован
                    ↓
5. Гость использует QR-код для регистрации входа/выхода
                    ↓
6. По истечении срока (valid_until) гость автоматически теряет доступ
   (попытка входа вернёт ошибку "гостевой пропуск истёк")
                    ↓
7. Администратор может досрочно отменить пропуск (revoke)
   → Аккаунт пользователя деактивируется (is_active=False)
```

---

## 🔒 Безопасность

### Проверки при входе

```python
if user.user_type == 'guest' and user.guest_valid_until:
    if timezone.now() > user.guest_valid_until:
        # Доступ запрещен
        return "Ваш гостевой пропуск истёк"
```

### Отмена пропуска

```python
guest_pass.revoke()
# Автоматически деактивирует связанный аккаунт:
# guest_pass.user.is_active = False
# guest_pass.user.save()
```

---

## 📋 API Reference

### Создание гостевого пропуска

**POST** `/guest-passes/`

**Request:**
```json
{
  "guest_name": "Иван Петров",
  "guest_company": "ABC Corp",
  "purpose": "temp_employee",
  "note": "Временный инженер",
  "guest_email": "ivan@abc.com",      // Опционально (для создания аккаунта)
  "guest_password": "Password123",    // Обязателен если указан email
  "valid_from": "2026-03-25T09:00:00Z",
  "valid_until": "2026-04-25T18:00:00Z"
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "guest_name": "Иван Петров",
  "user_email": "ivan@abc.com",       // Email созданного аккаунта
  "has_account": true,                // Был ли создан аккаунт
  "token": "a1b2c3d4e5f6...",
  "status": "active",
  "valid_from": "2026-03-25T09:00:00Z",
  "valid_until": "2026-04-25T18:00:00Z",
  "is_valid": true
}
```

---

### Список гостевых пропусков

**GET** `/guest-passes/`

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "guest_name": "Иван Петров",
    "status": "active",
    "has_account": true,
    "user_email": "ivan@abc.com",
    // ... другие поля
  }
]
```

---

### Отмена пропуска

**POST** `/guest-passes/{id}/revoke/`

**Response:** `200 OK`
```json
{
  "status": "revoked",
  "revoked_at": "2026-03-25T12:30:15Z"
}
```

---

## 🧪 Примеры использования

### Пример 1: Создание временного подрядчика на 1 день

```bash
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

curl -X POST http://localhost:8000/guest-passes/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "guest_name": "Сергей Иванов",
    "guest_company": "УК Стройграмм",
    "purpose": "contractor",
    "note": "Ремонт кровли здания A",
    "guest_email": "sergey.ivanov@stroygram.com",
    "guest_password": "TempPass2026",
    "valid_from": "2026-03-25T08:00:00Z",
    "valid_until": "2026-03-26T20:00:00Z"
  }'
```

### Пример 2: Создание гостевого пропуска БЕЗ аккаунта

```bash
curl -X POST http://localhost:8000/guest-passes/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "guest_name": "Курьер Петров Пётр",
    "guest_company": "Почта России",
    "purpose": "delivery",
    "note": "Доставка посылок",
    "valid_from": "2026-03-25T10:00:00Z",
    "valid_until": "2026-03-25T12:00:00Z"
  }'
```

**Результат:** Пропуск создан, но аккаунт НЕ создан (только QR-код)

### Пример 3: Проверка статуса гостевого аккаунта

```bash
# Гость входит
GUEST_TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ivan.petrov@abc.com","password":"SecurePass123"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null || echo "fail")

# Проверяем профиль
curl -s -X GET http://localhost:8000/auth/profile \
  -H "Authorization: Bearer $GUEST_TOKEN" \
  | python3 -m json.tool
```

---

## ❌ Распространённые ошибки

### Ошибка: "Email уже используется"
```json
{
  "detail": "Этот email уже используется"
}
```
**Решение:** Используйте уникальный email для каждого гостя

### Ошибка: "Пароль обязателен если указан email"
```json
{
  "detail": "Пароль обязателен если указан email"
}
```
**Решение:** Передайте оба поля: `guest_email` И `guest_password`

### Ошибка: "Ваш гостевой пропуск истёк"
```json
{
  "detail": "Ваш гостевой пропуск истёк"
}
```
**Решение:** Администратор должен создать новый пропуск с более поздней датой `valid_until`

---

## 📞 FAQ

**Q: Может ли гость редактировать свой профиль?**
A: Только аватарку и минимальные данные. Email и пароль изменить не может.

**Q: Что происходит после истечения пропуска?**
A: Гость не может войти в приложение. Администратор может создать новый пропуск.

**Q: Как отменить пропуск гостя?**
A: На админ-панеле выберите гостевой пропуск → **Revoke** → он перейдёт в статус "revoked" и аккаунт деактивируется.

**Q: Может ли гость видеть других гостей?**
A: Нет, каждый гость видит только свой профиль и пропуск.

---

*Последнее обновление: 25 марта 2026 г.*
