# 👨‍💻 Руководство для разработчиков

## Требования перед началом

- Python 3.11+ (для backend)
- Flutter SDK 3.11+ (для frontend)
- Docker и Docker Compose
- Git
- Текстовый редактор (VS Code, PyCharm, IntelliJ IDEA)

---

## 🚀 Установка окружения

### Backend разработка

```bash
cd backend

# Создать виртуальное окружение
python3 -m venv venv

# Активировать
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows

# Установить зависимости
pip install -r requirements.txt

# Запустить миграции
python entry_point/manage.py migrate

# Создать суперпользователя
python entry_point/manage.py createsuperuser

# Запустить сервер
python entry_point/manage.py runserver 0.0.0.0:8000
```

### Frontend разработка

```bash
cd entry_point

# Установить зависимости
flutter pub get

# Запустить на Android эмуляторе
flutter run

# Или на Chrome (web)
flutter run -d chrome --dart-define=BASE_URL=http://localhost:8000
```

---

## 📝 Соглашения кодирования

### Backend (Python)

#### PEP 8 Style Guide

```python
# ✅ Правильно
def calculate_user_attendance(user_id: int) -> List[AttendanceRecord]:
    """Calculate attendance for a specific user."""
    records = AttendanceRecord.objects.filter(user_id=user_id)
    return records

# ❌ Неправильно
def calcAttend(u):
    r = AttendanceRecord.objects.filter(user_id=u)
    return r
```

#### Именование

```python
# Переменные и функции — snake_case
user_id = 1
def get_user_by_email():
    pass

# Классы — PascalCase
class UserSerializer:
    pass

class QRCodeGenerator:
    pass

# Константы — UPPER_SNAKE_CASE
MAX_PASS_VALIDITY_DAYS = 365
DEFAULT_QR_SIZE = 200
```

#### Импорты

```python
# Порядок: стандартная библиотека, сторонние, локальные
import json
from datetime import datetime
from typing import List, Optional

from django.db import models
from rest_framework import serializers

from .models import User, Pass
```

---

### Frontend (Dart/Flutter)

#### Effective Dart

```dart
// ✅ Правильно: const для неизменяемых значений
const appTitle = 'Entry Point';

// ❌ Неправильно
var appTitle = 'Entry Point';

// ✅ Правильно: использовать final для одноразовых присваиваний
final userProvider = StateNotifierProvider<UserNotifier, User?>(
  (ref) => UserNotifier(),
);

// ✅ Правильно: типизация функций
Future<List<User>> fetchUsers() async {
  // ...
}

// ✅ Правильно: документация
/// Fetch all users from the API.
/// 
/// Returns a list of [User] objects or throws [ApiException].
Future<List<User>> fetchUsers() async {
  // ...
}
```

#### Структура класса

```dart
class UserModel {
  // Поля
  final int id;
  final String email;
  final String name;

  // Конструктор
  UserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  // JSON сериализация
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }

  // copyWith для создания копии с измененными полями
  UserModel copyWith({
    int? id,
    String? email,
    String? name,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }
}
```

---

## 🧪 Тестирование

### Backend тесты

```python
# tests.py или test_models.py

from django.test import TestCase
from django.contrib.auth import get_user_model

User = get_user_model()

class UserModelTests(TestCase):
    """Test cases for User model."""

    def setUp(self):
        """Create a test user."""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )

    def test_user_creation(self):
        """Test that user is created correctly."""
        self.assertEqual(self.user.email, 'test@example.com')
        self.assertTrue(self.user.check_password('testpass123'))

    def test_user_str(self):
        """Test user string representation."""
        self.assertEqual(str(self.user), 'test@example.com')
```

Запуск:
```bash
# Все тесты
docker-compose exec backend python entry_point/manage.py test

# Конкретное приложение
docker-compose exec backend python entry_point/manage.py test user

# Конкретный класс тестов
docker-compose exec backend python entry_point/manage.py test user.tests.UserModelTests

# С выводом
docker-compose exec backend python entry_point/manage.py test --verbosity=2
```

### Frontend тесты (Flutter)

```dart
// test/user_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:entry_point/data/repositories/user_repository.dart';

void main() {
  group('UserRepository', () {
    late UserRepository userRepository;

    setUp(() {
      userRepository = UserRepository();
    });

    test('fetchUser returns a User', () async {
      expect(
        await userRepository.fetchUser(1),
        isA<User>(),
      );
    });

    test('login returns access_token', () async {
      final result = await userRepository.login(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(result.accessToken, isNotEmpty);
    });
  });
}
```

Запуск:
```bash
cd entry_point

# Все тесты
flutter test

# Одного файла
flutter test test/user_repository_test.dart

# С покрытием
flutter test --coverage
```

---

## 📊 Git рабочий процесс

### Ветки

```
main          — production версия (стабильная)
develop       — development версия (интеграция)
feature/*     — новые фичи (feature/qr-scanner)
bugfix/*      — исправления (bugfix/login-error)
hotfix/*      — срочные исправления (hotfix/security-patch)
```

### Коммиты

#### Формат сообщения коммита

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Типы

- `feat` — новая фича
- `fix` — исправление баг
- `docs` — документация
- `style` — форматирование кода
- `refactor` — переписание кода без изменения функциональности
- `perf` — улучшение производительности
- `test` — добавление тестов
- `chore` — обновление зависимостей

#### Примеры

```bash
git commit -m "feat(auth): add JWT token refresh"
git commit -m "fix(qr-scanner): handle invalid QR codes"
git commit -m "docs: update README with API examples"
git commit -m "style: format user serializer"
git commit -m "test(attendance): add test cases for attendance CRUD"
```

### Pull Request процесс

1. **Создать ветку**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Сделать изменения и коммиты**:
   ```bash
   git add .
   git commit -m "feat(auth): add JWT token refresh"
   ```

3. **Пушить в GitHub**:
   ```bash
   git push origin feature/my-feature
   ```

4. **Создать Pull Request** на GitHub
5. **Код ревью** от других разработчиков
6. **Merge** в develop после одобрения

---

## 🔍 Code Review процесс

### Что проверять

✅ **Backend (Python)**
- Соответствие PEP 8
- Обработка ошибок (try/except)
- SQL запросы оптимизированы (N+1 queries?)
- Есть ли unit тесты?
- Документирован ли код?

✅ **Frontend (Flutter)**
- Соответствие Effective Dart
- Не использованы hardcoded значения
- Обработка ошибок (try/catch)
- Нет утечек памяти (dispose вызывается?)
- Тесты написаны?

### Примеры комментариев

```
// Пример хорошего комментария
// ✅ "Consider adding error handling for network failures"

// ❌ "This is bad" → Неполезно

// ✅ "Use const constructor instead of final to improve performance"

// ❌ "Wrong" → Нет объяснения
```

---

## 🚀 Развертывание на production

### Before Deploy

1. **Все тесты проходят**:
   ```bash
   docker-compose exec backend python entry_point/manage.py test
   cd entry_point && flutter test
   ```

2. **Нет ошибок линтеров**:
   ```bash
   # Backend
   docker-compose exec backend flake8 entry_point

   # Frontend
   cd entry_point && flutter analyze
   ```

3. **Code review одобрен**

4. **Миграции тестированы** на staging

### Deployment Steps

```bash
# 1. Merge в main
git checkout main
git pull origin main

# 2. Создать версию (semantic versioning)
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# 3. На сервере
cd /var/www/entry-point
git pull origin main

# 4. Запустить Docker контейнеры
docker-compose down
docker-compose pull
docker-compose up -d

# 5. Применить миграции
docker-compose exec backend python entry_point/manage.py migrate

# 6. Проверить статус
curl http://localhost:8000/api/health/
```

---

## 📚 Полезные ресурсы

### Backend (Django)

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Django ORM Query Optimization](https://docs.djangoproject.com/en/stable/topics/db/queries/)

### Frontend (Flutter)

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

### General

- [RESTful API Design Best Practices](https://restfulapi.net/)
- [Semantic Versioning](https://semver.org/)
- [Commit Message Guidelines](https://www.conventionalcommits.org/)

---

## 🆘 FAQ

**Q: Как я могу помочь проекту?**

A: Читайте Issues на GitHub, выбирайте интересующую вас задачу и создавайте PR!

**Q: Как сообщить об ошибке?**

A: Создайте Issue с описанием проблемы, шагами воспроизведения и окружением.

**Q: Как предложить новую фичу?**

A: Откройте Discussion на GitHub для обсуждения идеи перед разработкой.

---

**Happy coding! 🚀**

*Последнее обновление: 25 марта 2026 г.*
