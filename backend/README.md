# Backend — Django REST API

Backend приложение для системы учета посещаемости на производстве. Предоставляет REST API для управления пользователями, гостевыми пропусками, QR-кодами и отчетами.

## 📋 Содержание

- Управление пользователями и аутентификация
- QR-коды для входа/выхода
- Система гостевых пропусков
- Отчеты о посещаемости
- Администраторская панель
- REST API документация (Swagger)

## 🛠 Технологический стек

- **Python 3.11+**
- **Django 4.2+**
- **Django REST Framework**
- **PostgreSQL 14+**
- **Redis 6+**
- **drf-spectacular** (Swagger/OpenAPI)

## 🚀 Быстрый старт

### С Docker Compose (рекомендуется)

```bash
# Запуск всех сервисов
docker-compose up -d

# Применить миграции (автоматически при первом запуске)
docker-compose exec web python manage.py migrate

# Создать суперпользователя
docker-compose exec web python manage.py createsuperuser
```

### Локально

```bash
# Создать виртуальное окружение
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Установить зависимости
pip install -r requirements.txt

# Копировать конфигурацию
cp .env.example .env

# Применить миграции
python manage.py migrate

# Запустить сервер
python manage.py runserver
```

## 📚 API документация

После запуска сервера документация доступна по адресам:

- **Swagger UI**: http://localhost:8000/schema/swagger/
- **ReDoc**: http://localhost:8000/schema/redoc/
- **OpenAPI Schema**: http://localhost:8000/schema/

## 📁 Структура проекта

```
backend/
├── entry_point/              # Django project (главная конфигурация)
│   ├── settings.py           # Основные настройки Django
│   ├── urls.py               # Маршруты приложения
│   ├── asgi.py               # ASGI конфигурация
│   ├── wsgi.py               # WSGI конфигурация
│   ├── logging_middleware.py # Логирование
│   └── frontend_views.py     # Фронтенд views
│
├── core/                     # Основное приложение
│   ├── models.py             # Базовые модели
│   ├── views.py              # Core views
│   ├── admin.py              # Django admin конфигурация
│   └── migrations/           # Миграции БД
│
├── user/                     # Управление пользователями
│   ├── models.py             # User, UserDevice модели
│   ├── views.py              # Аутентификация и профиль
│   ├── serializers.py        # DRF сериализаторы
│   ├── urls.py               # User URLs
│   ├── authentication.py     # Кастомная аутентификация
│   ├── qr_views.py           # QR-код генерация
│   ├── sse_views.py          # Server-Sent Events
│   └── migrations/
│
├── scaner/                   # QR и гостевые пропуска
│   ├── models.py             # GuestPass, QRCode, AccessLog
│   ├── views.py              # QR валидация
│   ├── guest_views.py        # Управление гостевыми пропусками
│   ├── export_views.py       # Экспорт отчетов
│   ├── serializers.py        # DRF сериализаторы
│   ├── urls.py               # Scaner URLs
│   └── migrations/
│
├── requirements.txt          # Python зависимости
├── docker-compose.yml        # Docker Compose конфигурация
├── dockerfile                # Docker конфигурация
├── .env.example              # Пример переменных окружения
├── create_admin.py           # Скрипт создания админа
└── manage.py                 # Django управление
```

## 🗄 Модели данных

### User (Пользователь)
```python
- email: CharField (unique)
- name: CharField
- surname: CharField
- patronymic: CharField (опционально)
- password: PasswordField
- is_admin: BooleanField
- is_active: BooleanField
- user_type: CharField (regular/guest)
- avatar: ImageField (опционально)
- created_at: DateTimeField
- updated_at: DateTimeField
```

### GuestPass (Гостевой пропуск)
```python
- guest_email: EmailField
- guest_name: CharField
- guest_surname: CharField
- guest_patronymic: CharField (опционально)
- guest_company: CharField
- purpose: CharField (meeting/work/delivery)
- created_by: ForeignKey(User)
- valid_from: DateTimeField
- valid_until: DateTimeField
- is_revoked: BooleanField
- created_at: DateTimeField
```

### QRCode
```python
- user: ForeignKey(User)
- token: CharField (unique)
- used_at: DateTimeField (опционально)
- expires_at: DateTimeField
- created_at: DateTimeField
```

## 🔐 API Endpoints

### Аутентификация
- `POST /auth/first-admin/` - Создание первого администратора
- `POST /auth/login/` - Вход в систему
- `POST /auth/logout/` - Выход из системы
- `POST /auth/password-reset/` - Запрос на сброс пароля
- `POST /auth/password-reset/confirm/` - Подтверждение сброса пароля

### Пользователи
- `GET /users/me/` - Профиль текущего пользователя
- `POST /users/me/avatar/` - Загрузка аватара
- `GET /users/me/devices/` - Список устройств пользователя
- `POST /auth/create-user/` - Создание пользователя (только admin)

### QR-коды
- `POST /qr/generate/` - Генерация QR-кода
- `POST /qr/validate/` - Валидация QR-кода

### Гостевые пропуска
- `GET /guest-passes/` - Список гостевых пропусков
- `POST /guest-passes/` - Создание гостевого пропуска
- `POST /guest-passes/<id>/revoke/` - Отмена гостевого пропуска
- `POST /guest-passes/validate/` - Валидация гостевого пропуска

### Отчеты
- `GET /reports/attendance/` - Экспорт отчета о посещаемости (Excel)

## 🧪 Тесты

```bash
# Запустить все тесты
python manage.py test

# Запустить тесты конкретного приложения
python manage.py test user
python manage.py test scaner

# Запустить с покрытием кода
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

## 📝 Логирование

Приложение логирует все основные операции в файлы логов:

```
logs/
├── user.log       # Логи управления пользователями
├── scaner.log     # Логи QR и гостевых пропусков
├── django.log    # Общие Django логи
└── error.log     # Ошибки
```

## 🐛 Решение проблем

### Ошибка подключения к БД
```bash
# Проверить статус PostgreSQL контейнера
docker ps | grep postgres
docker logs spring-hack-postgres
```

### Ошибка Redis
```bash
# Проверить Redis
redis-cli ping
# Должен вернуть PONG
```

### Ошибка миграций
```bash
# Просмотреть статус миграций
python manage.py showmigrations

# Откатить последнюю миграцию
python manage.py migrate app_name 0001
```

## 🔄 Миграции БД

```bash
# Создать новую миграцию
python manage.py makemigrations

# Применить миграции
python manage.py migrate

# Показать SQL для миграции
python manage.py sqlmigrate app_name migration_number
```

## 📊 Администраторская панель

Django Admin доступна по адресу: http://localhost:8000/admin/

Учетные данные по умолчанию:
- **Username**: admin
- **Password**: admin (измените после первого входа!)

## 🚀 Развертывание

### Production переменные

Убедитесь, что в production установлены правильные переменные:

```env
DEBUG=False
SECRET_KEY=your-production-secret-key
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Безопасность
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### Используемые порты

- **8000** - Django приложение (API)
- **5432** - PostgreSQL
- **6379** - Redis

## 📞 Поддержка

Если у вас есть вопросы или проблемы:
- 📖 Смотрите [документацию](../README.md)
- 🐛 [Сообщите об ошибке](../../../issues)
- 💬 [Обсудите возможности](../../../discussions)

## 📄 Лицензия

MIT License - см. [LICENSE](../LICENSE)
