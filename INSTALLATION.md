# Установка и запуск

## Требования

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Git**
- **Браузер** (Chrome, Firefox, Safari)

### Для локальной разработки (опционально)

**Backend:**
- Python 3.11+
- pip/poetry
- PostgreSQL 14+
- Redis 6+

**Frontend:**
- Flutter 3.0+
- Dart 3.0+

## Быстрый старт (Docker)

### 1. Клонирование репозитория

```bash
git clone https://github.com/yourusername/spring-hack-2026.git
cd spring-hack-2026
```

### 2. Запуск через Docker Compose

```bash
cd backend
docker-compose up -d
```

Docker автоматически:
- Создаст контейнеры PostgreSQL, Redis, Django
- Выполнит миграции БД
- Создаст суперпользователя (если требуется)

### 3. Доступ к сервисам

| Сервис | URL | Учетные данные |
|--------|-----|---|
| **Backend API** | http://localhost:8000/api/ | - |
| **API Docs** | http://localhost:8000/schema/swagger/ | - |
| **Admin Panel** | http://localhost:8000/admin/ | admin/admin |
| **Frontend** | http://localhost:3000/ | - |

## Локальная разработка

### Backend (Django)

#### Подготовка окружения

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Конфигурация

```bash
# Скопировать пример .env
cp .env.example .env

# Изменить при необходимости
nano .env
```

#### Запуск

```bash
# Миграции БД
python manage.py migrate

# Создание суперпользователя
python manage.py createsuperuser

# Запуск сервера
python manage.py runserver
```

### Frontend (Flutter)

#### Подготовка

```bash
cd entry_point
flutter pub get
```

#### Запуск для веб

```bash
flutter run -d web-server --target lib/main.dart
```

#### Запуск для Android

```bash
flutter run -d android
```

#### Запуск для Linux

```bash
flutter run -d linux
```

## Структура проекта

```
spring-hack-2026/
├── .github/                  # GitHub workflows и templates
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── backend/                  # Django приложение
│   ├── entry_point/          # Django project
│   │   ├── core/             # Основные модели
│   │   ├── user/             # Управление пользователями
│   │   ├── scaner/           # QR и гостевые пропуска
│   │   └── manage.py
│   ├── dockerfile
│   ├── docker-compose.yml
│   ├── requirements.txt
│   └── create_admin.py
├── entry_point/              # Flutter приложение
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/             # Бизнес-логика
│   │   ├── data/             # API и хранилище
│   │   ├── domain/           # Сущности
│   │   ├── presentation/     # UI слой
│   │   ├── router/           # Маршрутизация
│   │   └── theme/            # Темы и стили
│   ├── pubspec.yaml
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── test/
├── .gitignore
├── README.md
├── ARCHITECTURE.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
└── LICENSE
```

## Решение проблем

### PostgreSQL не подключается

```bash
# Проверить запущен ли контейнер
docker ps | grep postgres

# Посмотреть логи
docker logs spring-hack-postgres
```

### Redis не подключается

```bash
# Проверить Redis
redis-cli -h localhost -p 6379 ping
# Должен вернуть PONG
```

### Flutter build ошибка

```bash
# Очистить кеш
flutter clean

# Переполучить зависимости
flutter pub get

# Пересобрать
flutter run
```

## Переменные окружения

Создайте файл `.env` в папке `backend/`:

```env
# Django
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgresql://postgres:password@db:5432/spring_hack

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Email (опционально)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

## Поддержка

Если у вас есть вопросы или проблемы:
- 📖 Смотрите [документацию](README.md)
- 🐛 [Сообщите об ошибке](https://github.com/yourusername/spring-hack-2026/issues)
- 💬 [Обсудите возможности](https://github.com/yourusername/spring-hack-2026/discussions)
