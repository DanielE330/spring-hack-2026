# Тестирование

Руководство по написанию и запуску тестов.

## 🧪 Backend тесты (Django)

### Unit тесты

```bash
cd backend/entry_point

# Запустить все тесты
python manage.py test

# Запустить конкретное приложение
python manage.py test user
python manage.py test scaner

# Запустить конкретный тест
python manage.py test user.tests.TestUserLogin

# С verbose выводом
python manage.py test --verbosity=2
```

### Покрытие кода

```bash
pip install coverage

# Запустить тесты с покрытием
coverage run --source='.' manage.py test
coverage report

# HTML отчет
coverage html
# Откройте htmlcov/index.html в браузере
```

### Пример unit теста (Backend)

```python
# backend/entry_point/user/tests.py
from django.test import TestCase
from .models import User

class UserModelTest(TestCase):
    def setUp(self):
        """Подготовка тестовых данных"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            name='Test',
            surname='User'
        )

    def test_user_creation(self):
        """Проверить создание пользователя"""
        self.assertEqual(self.user.email, 'test@example.com')
        self.assertTrue(self.user.check_password('testpass123'))

    def test_user_is_not_admin(self):
        """Проверить что новый пользователь не администратор"""
        self.assertFalse(self.user.is_admin)

    def test_user_string_representation(self):
        """Проверить строковое представление"""
        self.assertEqual(str(self.user), 'test@example.com')
```

## 📱 Frontend тесты (Flutter)

### Unit тесты

```bash
cd entry_point

# Запустить все тесты
flutter test

# Запустить конкретный файл
flutter test test/auth_repository_test.dart

# С verbose выводом
flutter test --verbose

# Только определенный тест
flutter test test/auth_repository_test.dart -k "login"
```

### Widget тесты

```dart
// entry_point/test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:entry_point/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
    // Создать виджет и запустить frame
    await tester.pumpWidget(const MyApp());

    // Проверить наличие элементов
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);

    // Ввести текст
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    
    // Нажать кнопку
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Проверить навигацию
    expect(find.text('Home'), findsOneWidget);
  });
}
```

### Покрытие кода (Flutter)

```bash
# Запустить тесты с покрытием
flutter test --coverage

# Просмотр отчета (требуется lcov)
# macOS/Linux
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Windows (используйте WSL или другой инструмент)
```

## 🔄 Интеграционные тесты

### Backend интеграционные тесты

```python
# backend/entry_point/user/tests.py
from django.test import Client, TestCase
from django.urls import reverse

class LoginAPITest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            name='Test',
            surname='User'
        )

    def test_login_endpoint(self):
        """Тестировать логин endpoint"""
        response = self.client.post(
            reverse('login'),
            {
                'email': 'test@example.com',
                'password': 'testpass123',
                'device_name': 'Test Device'
            },
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 200)
        self.assertIn('device_code', response.json())
```

### Flutter интеграционные тесты

```dart
// entry_point/test/integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:entry_point/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete login flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Вход
    await tester.enterText(
      find.byType(TextField).first,
      'test@example.com'
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Проверить что мы на главной странице
    expect(find.byType(HomePage), findsOneWidget);
  });
}
```

## 📊 CI/CD тесты

GitHub Actions автоматически запускает тесты при push:

```yaml
# .github/workflows/ci.yml
name: CI/CD

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Backend tests
        run: |
          cd backend
          pip install -r requirements.txt
          python manage.py test
      
      - name: Frontend tests
        uses: subosito/flutter-action@v2
      - run: |
          cd entry_point
          flutter test
```

## 🐛 Отладка тестов

### Backend отладка

```bash
# С print statements
python manage.py test --keepdb --verbosity=2

# С debugger (pdb)
# Добавить в тест:
import pdb; pdb.set_trace()

# С логированием
python manage.py test --debug-sql
```

### Flutter отладка

```bash
# Развернутый вывод
flutter test --verbose

# С отладкой
flutter test --start-paused
# затем нажать 'r' для запуска тестов

# Со скриншотами
flutter test --update-goldens
```

## 📈 Качество кода

### Backend (Python)

```bash
# Linting
pip install flake8 pylint

flake8 backend/
pylint backend/

# Type checking
pip install mypy
mypy backend/

# Форматирование
pip install black
black backend/
```

### Frontend (Dart)

```bash
# Анализ
cd entry_point
flutter analyze

# Форматирование
dart format lib/

# Линтинг (custom rules)
dart pub run custom_lint
```

## ✅ Чеклист перед release

- [ ] Все unit тесты проходят
- [ ] Все интеграционные тесты проходят
- [ ] Покрытие кода ≥ 70%
- [ ] Нет lint ошибок
- [ ] Нет warnings
- [ ] Код отформатирован
- [ ] CHANGELOG обновлен
- [ ] Версия обновлена в pubspec.yaml и requirements.txt
- [ ] README обновлен при необходимости

---

Последнее обновление: 25 марта 2026 г.
