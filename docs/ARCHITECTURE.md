# Архитектура и компоненты

Этот документ описывает архитектуру системы и основные компоненты.

## 🏛️ Общая архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                      Клиентское приложение                     │
│                    (Flutter Web/Mobile/Desktop)                │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTP/REST
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway                                │
│                    (Django REST Framework)                      │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
         ┌──────────┐  ┌──────────┐  ┌──────────┐
         │   User   │  │  Scaner  │  │  Core    │
         │  Module  │  │  Module  │  │  Module  │
         └────┬─────┘  └────┬─────┘  └────┬─────┘
              │             │             │
              └─────────────┼─────────────┘
                            │
                            ▼
         ┌──────────────────────────────────┐
         │     PostgreSQL Database          │
         │  (Users, GuestPass, QRCode, etc)│
         └──────────────────────────────────┘
         
         ┌──────────────────────────────────┐
         │     Redis Cache/Queue            │
         │  (Session, Temporary Data)       │
         └──────────────────────────────────┘
```

## 📦 Backend структура (Django)

### Приложения

#### 1. **core** — ядро приложения
- `models.py` — базовые модели и конфигурация
- `admin.py` — админ-панель
- `views.py` — основные представления

#### 2. **user** — управление пользователями
```
user/
├── models.py
│   ├── User — основная модель пользователя
│   ├── UserDevice — устройства пользователя
│   └── PasswordResetToken — расчеты сброса пароля
├── views.py
│   ├── FirstAdminView — создание первого администратора
│   ├── CreateUserView — создание пользователей
│   ├── LoginView — вход в систему
│   ├── LogoutView — выход
│   └── MeView — профиль текущего пользователя
├── qr_views.py
│   └── GenerateQRView — генерация QR-кодов
├── sse_views.py
│   └── EventStream — Server-Sent Events
├── serializers.py
│   ├── UserSerializer
│   ├── LoginSerializer
│   ├── LoginResponseSerializer
│   └── ...
└── urls.py
```

#### 3. **scaner** — сканирование QR и гостевые пропуска
```
scaner/
├── models.py
│   ├── QRCode — QR-коды
│   ├── GuestPass — гостевые пропуска
│   ├── AccessLog — логи доступа
│   ├── WeeklyRecord — недельные отчеты
│   ├── MonthlyRecord — ежемесячные отчеты
│   └── YearlyRecord — годовые отчеты
├── views.py
│   └── ValidateQRView — валидация QR-когда
├── guest_views.py
│   ├── GuestPassListCreateView
│   ├── GuestPassRevokeView
│   └── GuestPassValidateView
├── export_views.py
│   └── ExportAttendanceExcelView
├── serializers.py
└── urls.py
```

### Потоки данных

#### Аутентификация
```
1. POST /auth/login
   ↓
2. LoginView.post()
   ↓
3. authenticate(email, password)
   ↓
4. UserDevice создается
   ↓
5. Возвращается device_code токен
```

#### Генерация QR
```
1. POST /qr/generate
   ↓
2. GenerateQRView.post()
   ↓
3. Создается QRCode объект
   ↓
4. Генерируется PNG изображение
   ↓
5. Возвращается QR-код
```

#### Валидация QR
```
1. POST /qr/validate (с токеном QR)
   ↓
2. ValidateQRView.post()
   ↓
3. Проверяется существование и сроки
   ↓
4. Создается AccessLog запись
   ↓
5. Обновляются статистики (Weekly/Monthly/Yearly)
   ↓
6. Возвращается статус доступа
```

#### Гостевой пропуск
```
1. POST /guest-passes/ (с данными гостя)
   ↓
2. GuestPassListCreateView.post()
   ↓
3. Создается GuestPass объект
   ↓
4. Генерируется QR-код для пропуска
   ↓
5. Создается временный User (type='guest')
   ↓
6. Отправляется письмо гостю (опционально)
   ↓
7. Возвращается пропуск с QR
```

## 📱 Frontend структура (Flutter)

### Слои Чистой Архитектуры

```
Presentation Layer (UI)
    ↓ (зависит от)
Domain Layer (Business Logic)
    ↑ (реализует)
Data Layer (Implementation)
    ↓ (зависит от)
External Services (API, DB, Cache)
```

### Папки

#### `lib/presentation/`
- **pages/** — полные экраны приложения
  - `login_page.dart`
  - `profile_page.dart`
  - `guest_passes_page.dart`
  - `qr_scanner_page.dart`

- **widgets/** — переиспользуемые компоненты
  - `app_bar.dart`
  - `buttons.dart`
  - `dialogs.dart`

- **controllers/** — управление состоянием (StateNotifier)

#### `lib/domain/`
- **entities/** — основные сущности
  - `user.dart`
  - `guest_pass.dart`
  - `qr_code.dart`

- **repositories/** — интерфейсы репозиториев
  - `user_repository.dart`
  - `guest_repository.dart`

#### `lib/data/`
- **datasources/** — работа с API
  - `api_services.dart`
  - `dio_client.dart`

- **models/** — модели данных (расширяют entities)
  - `user_model.dart`
  - `guest_pass_model.dart`

- **repositories/** — реализация интерфейсов
  - `user_repository_impl.dart`
  - `guest_repository_impl.dart`

#### `lib/core/`
- **providers/** — Riverpod провайдеры состояния
- **constants/** — константы приложения
- **utils/** — утилиты и помощники

### Потоки данных

#### Вход пользователя
```
LoginPage
    ↓ (пользователь вводит email и пароль)
    ↓
LoginController (StateNotifier)
    ↓
UserRepository.login()
    ↓
UserDataSource.login() (HTTP запрос)
    ↓
API: POST /auth/login
    ↓
Ответ с device_code
    ↓
Сохраняется в SharedPreferences
    ↓
Переход на главную страницу
```

#### Сканирование QR
```
QRScannerPage
    ↓ (camera сканирует QR)
    ↓
onQRCodeDetected()
    ↓
QRController.validateQR()
    ↓
QRRepository.validate()
    ↓
API: POST /qr/validate
    ↓
Показ результата (успех/ошибка)
    ↓
AccessLog создается на сервере
```

#### Создание гостевого пропуска
```
GuestPassPage
    ↓ (админ вводит данные гостя)
    ↓
GuestController.createPass()
    ↓
GuestRepository.createPass()
    ↓
API: POST /guest-passes/
    ↓
GuestPass создается
    ↓
QR генерируется
    ↓
Показ пропуска с QR кодом
    ↓
Возможность поделиться или распечатать
```

## 🗄️ Database Schema

### User
```sql
id (PK)
email (UNIQUE)
name
surname
patronymic
password_hash
is_admin
is_active
user_type (regular/guest)
avatar (nullable)
created_at
updated_at
guest_valid_until (nullable)
```

### UserDevice
```sql
id (PK)
user_id (FK)
device_name
ip_address
key (UNIQUE)
is_active
last_used
created_at
```

### GuestPass
```sql
id (PK)
guest_email
guest_name
guest_surname
guest_patronymic
guest_company
purpose
note
created_by_id (FK)
valid_from
valid_until
is_revoked
created_at
```

### QRCode
```sql
id (PK)
user_id (FK)
token (UNIQUE)
used_at (nullable)
expires_at
created_at
```

### AccessLog
```sql
id (PK)
user_id (FK)
entry_type (entry/exit)
timestamp
device_ip (nullable)
qr_code_id (FK, nullable)
created_at
```

### WeeklyRecord
```sql
id (PK)
user_id (FK)
week_start
week_end
days_worked
total_seconds
is_finalized
created_at
```

## 🔄 Интеграция Framework'ов

### API <-> Backend
- HTTP/REST через Dio (Flutter)
- JWT токены для аутентификации
- Обработка ошибок (4xx, 5xx)

### Backend <-> Database
- ORM Django Models
- Миграции для изменений схемы

### Backend <-> Redis
- Кеширование сессий
- Временные данные (reset tokens)
- Rate limiting

### Frontend <-> LocalStorage
- Сохранение токенов (flutter_secure_storage)
- Кеш данных (shared_preferences)
- Оффлайн очередь действий

## 🔐 Безопасность

### Backend
- Django CSRF protection
- Django Security middleware
- Password hashing (PBKDF2)
- Rate limiting
- SQL injection protection (ORM)

### Frontend
- Secure token storage
- HTTPS only
- Certificate pinning (можно добавить)
- Input validation

### API
- JWT токены
- Device-based authorization
- Admin-only endpoints
- Permission checks

## 📊 Производительность

### Оптимизации Backend
- Database indexing
- ORM query optimization (select_related, prefetch_related)
- Redis caching
- Paginated responses

### Оптимизации Frontend
- Lazy loading
- Image caching
- State management (Riverpod)
- Widget rebuild optimization

---

Последнее обновление: 25 марта 2026 г.
