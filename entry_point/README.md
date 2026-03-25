# Frontend — Flutter приложение

Кроссплатформенное приложение для системы учета посещаемости. Работает на Web, Android, iOS, Linux, Windows и macOS.

## 📋 Содержание

- Аутентификация пользователей
- QR-сканирование для входа/выхода
- Управление гостевыми пропусками
- Просмотр отчетов о посещаемости
- Администраторская панель
- Поддержка темного режима

## 🛠 Технологический стек

- **Flutter 3.0+**
- **Dart 3.0+**
- **REST API** (HTTP/Dio)
- **Local Storage** (shared_preferences)
- **QR Scanner** (mobile_scanner)
- **File Picker** (file_picker)

## 🚀 Быстрый старт

### Требования

```bash
# Проверить Flutter
flutter doctor

# Должно быть:
# - Flutter SDK version 3.0+
# - Dart SDK version 3.0+
# - Минимум один доступный эмулятор/устройство
```

### Установка зависимостей

```bash
cd entry_point
flutter pub get
```

### Запуск на разных платформах

#### Web (рекомендуется для разработки)
```bash
flutter run -d web-server --target lib/main.dart
# Откроется на http://localhost:3000
```

#### Android
```bash
# Требуется Android Studio и эмулятор
flutter run -d android
```

#### iOS
```bash
# Требуется Xcode (только на macOS)
flutter run -d ios
```

#### Linux
```bash
flutter run -d linux
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

## 📁 Структура проекта

```
entry_point/
├── lib/
│   ├── main.dart                 # Точка входа приложения
│   ├── app.dart                  # Конфигурация приложения
│   │
│   ├── core/                     # Бизнес-логика и провайдеры
│   │   ├── providers/            # Riverpod провайдеры
│   │   ├── constants/            # Константы приложения
│   │   └── utils/                # Утилиты (validators, helpers)
│   │
│   ├── data/                     # Работа с данными
│   │   ├── datasources/          # API клиенты
│   │   ├── models/               # Модели данных
│   │   └── repositories/         # Репозитории (паттерн Repository)
│   │
│   ├── domain/                   # Сущности (entities/models)
│   │   ├── entities/             # Основные сущности приложения
│   │   └── repositories/         # Интерфейсы репозиториев
│   │
│   ├── presentation/             # UI слой
│   │   ├── pages/                # Полноэкранные страницы
│   │   ├── widgets/              # Переиспользуемые виджеты
│   │   ├── screens/              # Экраны (с логикой)
│   │   └── controllers/          # State management (StateNotifier)
│   │
│   ├── router/                   # Маршрутизация (GoRouter)
│   │   └── router.dart
│   │
│   └── theme/                    # Темы и стили
│       ├── app_theme.dart
│       ├── colors.dart
│       └── text_styles.dart
│
├── test/                         # Тесты
│   ├── unit/                     # Unit тесты
│   ├── widget/                   # Widget тесты
│   └── integration/              # Интеграционные тесты
│
├── pubspec.yaml                  # Зависимости и конфигурация
├── analysis_options.yaml         # Lint правила
├── android/                      # Android конфигурация
├── ios/                          # iOS конфигурация
├── web/                          # Web конфигурация
├── windows/                      # Windows конфигурация
├── linux/                        # Linux конфигурация
└── macos/                        # macOS конфигурация
```

## 📚 Архитектура

Приложение использует чистую архитектуру (Clean Architecture) с разделением на слои:

```
┌─────────────────────────────────┐
│ Presentation Layer (UI)         │ ← Виджеты, страницы, управление состоянием
├─────────────────────────────────┤
│ Domain Layer (Business Logic)   │ ← Сущности, интерфейсы репозиториев (не зависит от фреймворков)
├─────────────────────────────────┤
│ Data Layer (Implementation)     │ ← Репозитории, API клиенты, локальное хранилище
├─────────────────────────────────┤
│ External Services               │ ← HTTP, Database, Cache
└─────────────────────────────────┘
```

## 🔐 API конфигурация

Backend API URL можно настроить в:
```dart
// lib/data/datasources/api_constants.dart
const String API_BASE_URL = 'http://localhost:8000/api/';
```

## 🎨 Темизация

Приложение поддерживает светлую и темную темы:

```dart
// lib/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme() { ... }
  static ThemeData darkTheme() { ... }
}
```

## 🧪 Тесты

```bash
# Запустить все тесты
flutter test

# Запустить с покрытием кода
flutter test --coverage

# Генерировать отчет о покрытии
flutter test --coverage && llvm-cov show -format=html -o coverage/index.html coverage/lcov.info
```

## 📱 Требования для основных платформ

### Web
- Поддержка всех современных браузеров
- Требуется HTTPS в production

### Android
- Android 5.0 (API 21) и выше
- Google Play Services

### iOS
- iOS 11.0 и выше
- Xcode 13+

### Linux
- Ubuntu 20.04+
- Development tools

### Windows
- Windows 10 или выше
- Visual Studio Build Tools

## 🔄 State Management

Приложение использует **Riverpod** для управления состоянием:

```dart
// Определение провайдера
final userProvider = StateNotifierProvider((ref) => UserNotifier());

// Использование в виджете
final user = ref.watch(userProvider);
```

## 🚀 Сборка для Release

### Web
```bash
flutter build web --release
# Выход в build/web/
```

### Android
```bash
flutter build apk --release
flutter build appbundle --release
# Выход в build/app/outputs/
```

### iOS
```bash
flutter build ios --release
# Требуется Apple Developer аккаунт
```

### Безопасность
- Не коммитить в репозиторий
- Использовать secrets для API ключей
- Включить проверку целостности приложения

## 📊 Производительность

Рекомендации по оптимизации:

```dart
// Использовать const конструкторы
const MyWidget();

// Использовать keys для списков
ListView.builder(
  key: ValueKey(item.id),
  ...
)

// Дебаунс для частых операций
```

## 🐛 Решение проблем

### Flutter не найден
```bash
# Добавить Flutter в PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Ошибка при запуске на Web
```bash
# Очистить кеш
flutter clean

# Переполучить зависимости
flutter pub get

# Запустить снова
flutter run -d web-server
```

### Проблемы с зависимостями
```bash
# Получить обновления
flutter pub upgrade

# Проверить конфликты
flutter pub outdated
```

## 📞 Поддержка

Если у вас есть вопросы или проблемы:
- 📖 Смотрите [документацию](../README.md)
- 🐛 [Сообщите об ошибке](../../../issues)
- 💬 [Обсудите возможности](../../../discussions)

## 📄 Лицензия

MIT License - см. [LICENSE](../LICENSE)
