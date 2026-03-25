# 🎫 Spring Hack 2026 — Система учёта посещаемости

**Многоуровневая система для учёта посещаемости сотрудников, гостей и подрядчиков на производстве.**

## 📋 Описание

- **📱 Flutter приложение** (entry_point): Web/Android/iOS, QR-пропуска, гостевые пропуска, админ-панель
- **🔧 Django Backend** (backend): REST API, хранение данных, управление пропусками, отчёты
- **📦 PostgreSQL + Redis**: Хранилище данных и кеширование

---

## 🚀 Быстрый старт (5 минут)

### Требования
- **Docker & Docker Compose**
- **Браузер** (Chrome, Firefox, Safari)

### Запуск приложения

```bash
# 1. Перейти в папку backend
cd backend

# 2. Запустить Docker контейнеры
docker-compose up -d

# 3. Готово! Приложение работает на http://localhost:8000/
```

**Первый запуск:** миграции БД выполняются автоматически.

---

## 🌐 Доступ к приложению

| Сервис | URL | Описание |
|--------|-----|---------|
| **Backend API** | http://localhost:8000/api/ | REST API документация |
| **Django Admin** | http://localhost:8000/admin/ | Администраторская панель |
| **PostgreSQL** | localhost:5432 | База данных (пользователь: postgres) |
| **Redis** | localhost:6379 | Кеширование и очереди |

---

## 📁 Структура проекта

```
spring-hack-2026/
├── backend/                    # Django приложение
│   ├── docker-compose.yml     # Конфиг для Docker
│   ├── dockerfile             # Образ приложения
│   ├── requirements.txt        # Python зависимости
│   └── entry_point/           # Django проект
│       ├── manage.py
│       ├── core/              # Основные модели
│       ├── user/              # Учётные записи пользователей
│       ├── scaner/            # Сканирование QR кодов
│       └── entry_point/
│           ├── settings.py    # Django конфиг
│           ├── urls.py        # Маршруты API
│           └── wsgi.py        # WSGI приложение
│
├── entry_point/               # Flutter приложение
│   ├── pubspec.yaml          # Flutter зависимости
│   ├── lib/
│   │   ├── main.dart         # Точка входа
│   │   ├── app.dart          # MaterialApp
│   │   ├── presentation/     # UI слой (страницы, виджеты)
│   │   ├── domain/           # Бизнес-логика (entities, usecases)
│   │   ├── data/             # Доступ к данным (models, API)
│   │   ├── router/           # GoRouter навигация
│   │   ├── theme/            # Темы оформления
│   │   └── core/             # Утилиты, константы, сетевой код
│   ├── test/                 # Unit и widget тесты
│   └── build/                # Скомпилированное приложение
│
└── README.md                  # Этот файл
```

---

## ⚙️ Конфигурация

### Переменные окружения

Создайте файл `backend/entry_point/.env`:

```ini
# Дополнительные переменные (опционально)
DB_PASSWORD=postgres
HOST_PORT=8000
DEBUG=True
```

**По умолчанию:**
- `HOST_PORT=8000` — порт приложения
- `DB_PASSWORD=postgres` — пароль БД
- Все контейнеры имеют автоматический перезапуск

---

## 🛑 Управление контейнерами

```bash
# Запустить все сервисы
docker-compose up -d

# Остановить
docker-compose down

# Остановить и удалить данные
docker-compose down -v

# Посмотреть логи
docker-compose logs -f backend
docker-compose logs -f db

# Перезапустить конкретный сервис
docker-compose restart backend

# Войти в контейнер
docker-compose exec backend bash
docker-compose exec db psql -U postgres
```

---

## 🗄️ Работа с БД

### Миграции Django

```bash
# Внутри контейнера: применить миграции
docker-compose exec backend python entry_point/manage.py migrate

# Создать суперпользователя (администратор)
docker-compose exec backend python entry_point/manage.py createsuperuser

# Создать суперпользователя автоматически
docker-compose exec backend python backend/create_admin.py
```

### Подключение к PostgreSQL

```bash
# Через psql
docker-compose exec db psql -U postgres -d postgres

# Или используйте GUI клиент (DBeaver, pgAdmin):
# Хост: localhost
# Порт: 5432
# Пользователь: postgres
# Пароль: postgres (по умолчанию)
```

---

## 🔐 Аутентификация и авторизация

### API endpoints

| Метод | Endpoint | Описание |
|-------|----------|---------|
| POST | `/auth/login` | Вход через email + пароль |
| POST | `/auth/register` | Регистрация нового пользователя |
| POST | `/auth/refresh` | Обновить JWT токен |
| GET | `/auth/profile` | Профиль текущего пользователя |
| POST | `/auth/logout` | Выход |

### Пример запроса

```bash
# Вход
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'

# Ответ:
# {
#   "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
#   "user": {"id": 1, "email": "admin@example.com", "name": "Admin"}
# }
```

Используйте `access_token` для всех API запросов в заголовке `Authorization: Bearer <token>`.

---

## 📱 QR-пропуска

### Основной цикл

1. **Администратор** создаёт пропуск для сотрудника/гостя в админ-панели
2. **QR-код** автоматически генерируется и передаётся пользователю
3. **Мобильное приложение** сканирует QR при входе/выходе
4. **Система** регистрирует перемещение в БД

### API для сканирования

```bash
curl -X POST http://localhost:8000/qr/validate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"qr_code":"ABC123DEF456"}'

# Ответ:
# {
#   "status": "success",
#   "user": {"id": 1, "name": "John Doe"},
#   "entry": {"timestamp": "2026-03-25T10:30:00Z", "type": "entry"}
# }
```

---

## 👥 Управление пропусками

### Виды пропусков

| Тип | Создатель | Действие | Пример |
|-----|-----------|---------|---------|
| **Постоянный** | Администратор | Сотрудник компании | Инженер, Менеджер, Охранник |
| **Гостевой** | Администратор | Краткосрочный доступ | Посетитель, Подрядчик |
| **Временный** | Администратор | С ограничением по времени | Практикант (1 месяц), Поставщик |

### Создание гостевого пропуска

```bash
curl -X POST http://localhost:8000/guest-passes/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Smith",
    "company": "ABC Corp",
    "purpose": "Встреча с менеджером",
    "valid_from": "2026-03-25T09:00:00Z",
    "valid_until": "2026-03-25T17:00:00Z",
    "phone": "+79999999999",
    "email": "john@abccorp.com"
  }'
```

---

## 📊 Отчёты и аналитика

### Доступные отчёты

1. **Посещаемость сотрудников** — список входов/выходов
2. **Активность гостей** — кто и когда посетил
3. **Нарушения** — попытки входа без пропуска
4. **График по часам** — загружённость в течение дня

### Примеры

```bash
# Посещаемость за день
curl -X GET 'http://localhost:8000/reports/attendance?date=2026-03-25' \
  -H "Authorization: Bearer <token>"

# Гости на сегодня
curl -X GET 'http://localhost:8000/reports/guests?date=2026-03-25' \
  -H "Authorization: Bearer <token>"
```

---

## 🔧 Разработка

### Backend разработка

```bash
# Если нужна локальная разработка без Docker
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Запустить сервер
python entry_point/manage.py runserver 0.0.0.0:8000

# Или с горячей перезагрузкой через Docker volumes (в docker-compose.yml уже настроено)
docker-compose up
```

### Frontend разработка (Flutter)

```bash
cd entry_point

# Установить зависимости
flutter pub get

# Запустить на Android эмуляторе
flutter run

# Запустить на iOS (только macOS)
flutter run -d "iPhone 15"

# Web версия
flutter run -d chrome --dart-define=BASE_URL=http://localhost:8000
```

### Создание и запуск тестов

```bash
# Unit тесты
flutter test

# Тесты с покрытием
flutter test --coverage

# Backend тесты
docker-compose exec backend python entry_point/manage.py test
```

---

## 🐛 Решение проблем

### Контейнер не запускается

```bash
# Посмотреть ошибки
docker-compose logs backend

# Перестроить образ
docker-compose up -d --build

# Если порт занят
sudo lsof -i :8000
```

### БД недоступна

```bash
# Проверить контейнер БД
docker-compose ps db

# Перезагрузить БД
docker-compose restart db

# Проверить подключение
docker-compose exec backend python entry_point/manage.py shell
```

### Миграции не применены

```bash
# Применить вручную
docker-compose exec backend python entry_point/manage.py migrate

# Или удалить данные и пересоздать
docker-compose down -v
docker-compose up -d
```

---

## 📚 Дополнительные ресурсы

- **Django документация**: https://docs.djangoproject.com/
- **Flutter документация**: https://flutter.dev/docs
- **PostgreSQL**: https://www.postgresql.org/docs/
- **REST API best practices**: https://restfulapi.net/

---

## 👨‍💼 Команда разработчиков

Проект разработан как решение для Hack Spring 2026.

**Лицензия**: MIT

---

## 📞 Поддержка

По вопросам обращайтесь к ближайшему разработчику или создайте issue в репозитории.

**Последнее обновление**: 25 марта 2026 г.
