# 🏗️ Архитектура системы — Spring Hack 2026

## Общая структура

```
┌─────────────────────────────────────────────────────────────┐
│                  Frontend (Flutter Web/Mobile)               │
│        QR-сканирование, Админ-панель, Профиль             │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP/REST
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Backend (Django REST API)                       │
│  ├─ Аутентификация (JWT)                                    │
│  ├─ Управление пропусками                                  │
│  ├─ QR-кодирование/декодирование                          │
│  ├─ Отчёты и аналитика                                     │
│  └─ Интеграция с БД и Redis                                │
└────┬────────────────────────────────────────────┬───────────┘
     │                              │
     ▼                              ▼
┌──────────────────┐    ┌──────────────────────┐
│   PostgreSQL 15  │    │     Redis 7-Alpine   │
│   (основная БД)  │    │  (кеш и сессии)     │
└──────────────────┘    └──────────────────────┘
```

---

## 🔐 Архитектура безопасности

### Аутентификация

1. **Вход**: email + пароль → Django
2. **Генерация**: JWT токены (access + refresh)
3. **Хранение**: flutter_secure_storage (мобильный)
4. **Отправка**: Authorization: Bearer <token>
5. **Проверка**: на каждый запрос (JWT middleware)

### Авторизация

- **Администратор** — создание/удаление пропусков, отчёты, управление пользователями
- **Сотрудник** — просмотр своего профиля, сканирование QR при входе
- **Гость** — только просмотр информации о пропуске

---

## 📦 Backend слои

### 1. **Models** (user/models.py, scaner/models.py)

```
User
├─ id, email, password_hash
├─ first_name, last_name
├─ is_admin, is_active
└─ created_at, updated_at

Pass
├─ id, user_id
├─ qr_code (уникальный)
├─ type (permanent, guest, temporary)
├─ valid_from, valid_until
└─ is_revoked

AttendanceRecord
├─ id, pass_id, user_id
├─ timestamp
├─ type (entry/exit)
└─ location (опционально)
```

### 2. **Serializers** (scaner/serializers.py, user/serializers.py)

- `UserSerializer` — профиль пользователя
- `PassSerializer` — информация о пропуске
- `AttendanceSerializer` — запись о входе/выходе
- `GuestPassSerializer` — гостевой пропуск

### 3. **Views / ViewSets** (scaner/views.py, user/views.py)

```
/api/users/
├─ GET /profile/          — профиль текущего пользователя
├─ PATCH /profile/        — обновить профиль
└─ POST /change-password/ — смена пароля

/api/passes/
├─ GET /                  — список пропусков
├─ GET /:id/              — детали пропуска
├─ POST /                 — создать пропуск
└─ DELETE /:id/           — отозвать пропуск

/api/attendance/
├─ GET /                  — история входов/выходов
└─ POST /scan/            — сканирование QR

/api/auth/
├─ POST /login/           — вход
├─ POST /register/        — регистрация
├─ POST /refresh/         — обновить токен
└─ POST /logout/          — выход
```

### 4. **Middleware**

- **JWT Middleware** — проверка токена на каждый запрос
- **CORS** — доступ с Flutter приложения
- **LoggingMiddleware** — логирование всех запросов

---

## 📱 Frontend слои (Flutter)

### 1. **Presentation层**

Экраны (Pages):
- `LoginPage` — авторизация
- `HomePage` — главная страница с QR-сканером
- `ProfilePage` — профиль пользователя
- `PassesPage` — список пропусков
- `AdminPage` — админ-панель

### 2. **Domain层**

Entities:
```dart
class User {
  final int id;
  final String email;
  final String name;
  final bool isAdmin;
}

class Pass {
  final int id;
  final String qrCode;
  final DateTime validFrom;
  final DateTime validUntil;
}
```

### 3. **Data層**

Models (DTO):
```dart
class UserModel extends User {
  // JSON сериализация
  factory UserModel.fromJson(Map<String, dynamic> json) => ...
}
```

Data Sources:
- **RemoteDataSource** — HTTP запросы через Dio
- **LocalDataSource** — flutter_secure_storage для токенов

### 4. **Riverpod Providers**

- `authProvider` — состояние аутентификации
- `passesProvider` — список пропусков
- `userProvider` — профиль пользователя
- `themeProvider` — текущая тема (светлая/тёмная)

---

## 🔄 Процесс QR-сканирования

```
Пользователь нажимает "Сканировать QR"
  ▼
Flutter открывает камеру (mobile_scanner)
  ▼
Пользователь направляет на QR-код
  ▼
mobile_scanner декодирует QR → получает UUID или код
  ▼
Отправляем POST /api/attendance/scan/ 
  { "qr_code": "ABC123DEF456" }
  ▼
Django проверяет:
  • Пропуск существует?
  • Не отозван?
  • Еще не истёк?
  ▼
ДА — создаёт AttendanceRecord, возвращает success
НЕТ — возвращает ошибку
  ▼
Flutter показывает результат (✅ Успешно / ❌ Ошибка)
```

---

## 🗄️ Структура БД

### Таблицы PostgreSQL

```sql
-- Пользователи
CREATE TABLE user (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE,
  password_hash VARCHAR(255),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  is_admin BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Пропуска
CREATE TABLE scaner_pass (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES user(id),
  qr_code VARCHAR(255) UNIQUE,
  type VARCHAR(20), -- 'permanent', 'guest', 'temporary'
  valid_from TIMESTAMP,
  valid_until TIMESTAMP,
  is_revoked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- История входов/выходов
CREATE TABLE scaner_attendancerecord (
  id SERIAL PRIMARY KEY,
  pass_id INTEGER REFERENCES scaner_pass(id),
  user_id INTEGER REFERENCES user(id),
  record_type VARCHAR(10), -- 'entry', 'exit'
  timestamp TIMESTAMP DEFAULT NOW(),
  location VARCHAR(255)
);

-- Гостевые пропуска
CREATE TABLE scaner_guestpass (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(255),
  company VARCHAR(255),
  purpose TEXT,
  phone VARCHAR(20),
  email VARCHAR(255),
  valid_from TIMESTAMP,
  valid_until TIMESTAMP,
  qr_code VARCHAR(255) UNIQUE,
  created_by_id INTEGER REFERENCES user(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🚀 Деплой (Production)

### Docker Compose (Development + Production)

1. **PostgreSQL** — основная БД
2. **Redis** — сессии и кеш
3. **Django** (Gunicorn) — приложение на порту 8000
4. **Nginx** (опционально) — reverse proxy, статику

### Переменные окружения (production)

```ini
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=example.com,www.example.com
DB_PASSWORD=secure-password
REDIS_PASSWORD=secure-password
```

### GitHub Actions CI/CD

- Push → Тестирование → Деплой на сервер

---

## 📊 Производительность и масштабирование

### Оптимизации

1. **Кеширование** — Redis для часто используемых данных
2. **Пагинация** — API возвращает 20 записей за раз
3. **Индексы БД** — на email, qr_code, user_id
4. **Connection pooling** — управление соединениями с БД

### Масштабирование

- Несколько инстансов Gunicorn за Nginx load balancer
- PostgreSQL master-slave репликация
- Redis Cluster для кеша
- CDN для статических файлов Flutter

---

## 🧪 Тестирование

### Backend тесты

```bash
# Unit тесты
docker-compose exec backend python entry_point/manage.py test user
docker-compose exec backend python entry_point/manage.py test scaner

# С покрытием
docker-compose exec backend coverage run -m pytest
docker-compose exec backend coverage report
```

### Frontend тесты (Flutter)

```bash
flutter test              # Unit + Widget тесты
flutter test --coverage   # С покрытием
```

---

## 🔍 Мониторинг и логирование

### Логирование Django

- `/logs/` папка в контейнере
- Уровни: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Формат: `[TIMESTAMP] LEVEL [module] Message`

### Мониторинг

- **Health Check**: GET /api/health/ — проверка статуса
- **Логи контейнеров**: `docker-compose logs -f`
- **Метрики**: можно добавить Prometheus + Grafana

---

## 🔗 Интеграции

### Внешние API (опционально)

- **Email** (Mailgun, SendGrid) — отправка QR гостям
- **SMS** (Twilio) — уведомления
- **Slack** — уведомления о нарушениях
- **CSV Export** — отчёты в Excel

---

## 📝 Соглашения кодирования

### Backend (Python/Django)

- PEP 8
- Каждый ViewSet должен иметь unit тесты
- Логирование всех ошибок

### Frontend (Dart/Flutter)

- Effective Dart
- Riverpod для state management
- GoRouter для навигации
- Темизация через ThemeData

---

**Версия**: 1.0  
**Дата обновления**: 25 марта 2026 г.
