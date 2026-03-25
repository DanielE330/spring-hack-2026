# ⚡ Быстрый старт — 5 минут

## Требования перед началом

- ✅ Docker и Docker Compose установлены
- ✅ Браузер (Chrome, Firefox, Safari)
- ✅ Терминал (bash/зшь)
- ✅ Интернет

---

## 🚀 Шаг 1: Запуск проекта

```bash
# Перейти в папку backend
cd backend

# Запустить все контейнеры
docker-compose up -d

# Установка завершена!
```

**Что происходит автоматически:**
- ✅ PostgreSQL БД запускается на `localhost:5432`
- ✅ Redis запускается на `localhost:6379`  
- ✅ Django Backend запускается на `localhost:8000`
- ✅ Миграции БД применяются автоматически
- ✅ Статические файлы генерируются

---

## 🌐 Шаг 2: Проверка работы

Откройте в браузере:

| Адрес | Описание | Ожидаемый результат |
|-------|---------|-------------------|
| **http://localhost:8000/** | Главная страница | Welcome страница Django |
| **http://localhost:8000/admin/** | Админ-панель | Форма входа |
| **http://localhost:8000/api/** | API документация | DRF API root |

---

## 👤 Шаг 3: Создание администратора

```bash
# Способ 1: Интерактивно
docker-compose exec backend python entry_point/manage.py createsuperuser

# Способ 2: Автоматически (если есть скрипт)
docker-compose exec backend python create_admin.py
```

**Вводимые данные:**
```
Email: admin@example.com
Пароль: admin123
```

Затем:
1. Откройте http://localhost:8000/admin/
2. Введите email и пароль
3. ✅ Вошли в админ-панель!

---

## 📱 Шаг 4: Тестирование API

### Проверить если приложение живо

```bash
curl http://localhost:8000/api/
```

**Ожидаемый ответ:**
```json
{
  "users": "http://localhost:8000/api/users/",
  "passes": "http://localhost:8000/api/passes/",
  "attendance": "http://localhost:8000/api/attendance/"
}
```

### Авторизация

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

**Ответ:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "admin@example.com",
    "name": "Admin"
  }
}
```

**Сохраните** `access_token` для следующих запросов!

### Получить профиль (требуется токен)

```bash
curl -X GET http://localhost:8000/auth/profile/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

---

## 🛠️ Основные команды

### Управление контейнерами

```bash
cd backend

# Запустить
docker-compose up -d

# Остановить
docker-compose down

# Перезагрузить
docker-compose restart backend

# Посмотреть логи
docker-compose logs -f backend
docker-compose logs -f db

# Войти в контейнер
docker-compose exec backend bash
```

### Работа с БД

```bash
# Применить миграции
docker-compose exec backend python entry_point/manage.py migrate

# Создать миграцию
docker-compose exec backend python entry_point/manage.py makemigrations

# Подключиться к PostgreSQL
docker-compose exec db psql -U postgres -d postgres

# Очистить БД (осторожно!)
docker-compose exec backend python entry_point/manage.py flush
```

### Тестирование

```bash
# Запустить тесты
docker-compose exec backend python entry_point/manage.py test

# Со статистикой покрытия
docker-compose exec backend coverage run -m pytest
```

---

## 🐛 Решение типичных проблем

### ❌ Проблема: Порт 8000 уже занят

```bash
# Найти процесс
sudo lsof -i :8000

# Убить процесс
kill -9 <PID>

# Или используйте другой порт
export HOST_PORT=8001
docker-compose up -d
```

### ❌ Проблема: БД не подключается

```bash
# Проверить контейнер БД
docker-compose ps db

# Посмотреть логи БД
docker-compose logs db

# Перезагрузить
docker-compose restart db

# Или пересоздать
docker-compose down -v
docker-compose up -d
```

### ❌ Проблема: Миграции не применены

```bash
# Применить вручную
docker-compose exec backend python entry_point/manage.py migrate

# Или если ошибка в миграциях
docker-compose exec backend python entry_point/manage.py migrate --fake-initial
```

### ❌ Проблема: Забыл пароль администратора

```bash
# Создать нового администратора
docker-compose exec backend python entry_point/manage.py createsuperuser

# Или сбросить пароль текущего
docker-compose exec backend python entry_point/manage.py changepassword admin
```

---

## 📊 Тестовые данные

### Создать тестового пользователя в админ-панели

1. Откройте http://localhost:8000/admin/
2. **Users** → Add user
3. Заполните поля:
   - Email: `test@example.com`
   - Password: `test123`
4. **Save**

### Создать тестовый пропуск

1. **Passes** → Add Pass
2. Выберите пользователя
3. Тип: **Permanent**
4. QR Code: сгенерируется автоматически
5. **Save**

---

## 🎯 Следующие шаги

После успешного запуска:

1. **Изучите API документацию**:
   - http://localhost:8000/api/
   - http://localhost:8000/admin/ — админ-панель

2. **Прочитайте подробную документацию**:
   - `README.md` — основное описание
   - `ARCHITECTURE.md` — архитектура системы

3. **Начните разработку**:
   - Backend: Редактируйте файлы в `backend/entry_point/`
   - Frontend: Перейдите в `entry_point/` и запустите `flutter run`

4. **Развертыванием на сервер**:
   - Используйте Docker Compose на production сервере
   - Настройте переменные окружения в `.env`

---

## 📞 Нужна помощь?

1. **Проверьте логи**:
   ```bash
   docker-compose logs -f
   ```

2. **Перезагрузитесь**:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

3. **Очистите кеш Docker**:
   ```bash
   docker system prune -a --volumes
   ```

4. **Обратитесь к команде разработки**

---

**Happy coding! 🚀**

*Последнее обновление: 25 марта 2026 г.*
