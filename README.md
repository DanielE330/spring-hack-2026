# Spring Hack 2026 — Система учёта посещаемости

**Многоуровневая система для учёта посещаемости сотрудников, гостей и подрядчиков.**

- Flutter Web/Мобильное приложение (entry_point): QR-пропуска, гостевые пропуска, админка
- Django Backend (backend): API, хранение данных, отчёты, гостевые пропуска

---

# Backend (Django)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

---

# Временные пропуска (гости/подрядчики)
- Создаются администратором в разделе "Администрирование"
- Можно задать ФИО, компанию, цель, время действия, комментарий
- QR-код пропуска можно отправить гостю (по email/SMS — опционально)
- Пропуск можно отозвать досрочно

---

# Деплой Web + Caddy

```bash
cd entry_point
flutter build web --release
rsync -avz --delete build/web/ root@your-server:/var/www/entry_point/
```

Caddyfile (пример):
```caddyfile
http://your-domain.com {
    handle /auth/* {
        reverse_proxy localhost:8000
    }
    handle /users/* {
        reverse_proxy localhost:8000
    }
    handle /qr/* {
        reverse_proxy localhost:8000
    }
    handle /reports/* {
        reverse_proxy localhost:8000
    }
    handle /admin/* {
        reverse_proxy localhost:8000
    }
    handle /guest-passes/* {
        reverse_proxy localhost:8000
    }
    handle /django-admin/* {
        reverse_proxy localhost:8000
    }
    handle /media/* {
        reverse_proxy localhost:8000
    }
    handle {
        root * /var/www/entry_point
        encode gzip
        try_files {path} /index.html
        file_server
    }
}
```

---

## Точка входа — Flutter Application

Кросс-платформенное мобильное приложение (Android / iOS) на Flutter.  
Стек: Flutter, Dio, flutter_riverpod, flutter_secure_storage, go_router.

---

## Быстрый старт

### Требования
- Flutter SDK **stable** (≥ 3.11)
- Dart SDK **3.11+**
- Android: API 21+
- iOS: iOS 12+

### Установка

```bash
# Клонировать репозиторий
git clone <repo-url>
cd fhck-spring-2026/entry_point

# Установить зависимости
flutter pub get
```

### Настройка `BASE_URL`

Переменная конфигурации передаётся через `--dart-define`:

```bash
flutter run --dart-define=BASE_URL=https://api.example.com
```

Или задайте её в `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "entry_point",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=BASE_URL=https://api.example.com"]
    }
  ]
}
```

По умолчанию используется `http://194.113.106.32` (Android-эмулятор → localhost).

### Запуск

```bash
flutter run
```

---

## Архитектура

```
lib/
├── main.dart                 # Точка входа
├── app.dart                  # MaterialApp.router
├── theme/
│   ├── app_colors.dart       # Цвета DarkColors / LightColors
│   └── app_themes.dart       # DarkTheme / LightTheme
├── core/
│   ├── constants/            # ApiConstants
│   ├── errors/               # Failure, AppException
│   ├── network/              # ApiClient, интерсепторы
│   ├── storage/              # SecureStorage (flutter_secure_storage)
│   └── utils/                # Validators
├── domain/
│   ├── entities/             # User, Item, ItemsPage
│   ├── repositories/         # Абстрактные интерфейсы
│   └── usecases/             # Бизнес-логика
├── data/
│   ├── models/               # JSON DTO (UserModel, ItemModel)
│   ├── sources/              # Remote data sources (dio)
│   └── repositories/         # Имплементации репозиториев
├── presentation/
│   ├── providers/            # Riverpod providers (auth, items, theme)
│   ├── pages/                # Экраны (auth, items, profile)
│   └── widgets/              # Переиспользуемые компоненты
├── router/
│   └── app_router.dart       # GoRouter + редиректы
└── l10n/
    ├── app_en.arb            # English strings
    └── app_ru.arb            # Russian strings
```

---

## Темы

Файлы темы:
- [`lib/theme/app_colors.dart`](lib/theme/app_colors.dart) — константы цветов `DarkColors` / `LightColors`
- [`lib/theme/app_themes.dart`](lib/theme/app_themes.dart) — `DarkTheme.theme` / `LightTheme.theme`

Подключение в `MaterialApp`:
```dart
MaterialApp.router(
  theme: LightTheme.theme,
  darkTheme: DarkTheme.theme,
  themeMode: themeMode,  // управляется ThemeModeNotifier
)
```

Сменить тему: Profile → «Тема оформления» (Системная / Светлая / Тёмная).

---

## Тестирование

```bash
# Unit + widget тесты
flutter test

# С покрытием
flutter test --coverage
```

---

## Сборка релиза

### Android APK

```bash
flutter build apk --release --dart-define=BASE_URL=https://api.example.com
# Артефакт: build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA (требуется macOS + Xcode)

```bash
flutter build ios --release --dart-define=BASE_URL=https://api.example.com
```

---

## CI / CD

GitHub Actions: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

| Триггер | Действия |
|---------|----------|
| push / PR → main, develop | `flutter analyze`, `dart format`, `flutter test` |
| Release tag | + build APK, build iOS |

Secrets необходимые в репозитории:
- `API_BASE_URL` — URL backend API для релизного билда

---

## API контракт

| Метод | Endpoint | Описание |
|-------|----------|----------|
| POST | `/auth/login` | Авторизация → `{access_token, refresh_token, user}` |
| POST | `/auth/register` | Регистрация → `{user}` |
| POST | `/auth/refresh` | Обновление токена → `{access_token}` |
| GET | `/auth/profile` | Профиль текущего пользователя |
| GET | `/items?page&per_page&query` | Список с пагинацией |
| GET | `/items/:id` | Детали элемента |
| POST | `/items` (multipart) | Создать элемент с файлом |
| PUT | `/items/:id` | Обновить |
| DELETE | `/items/:id` | Удалить |

**Формат ошибки:**
```json
{
  "status": 422,
  "message": "Validation error",
  "errors": {
    "email": ["Email is already taken"]
  }
}
```

---

## Контакты

По вопросам API обращайтесь к backend-команде.
