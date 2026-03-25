# Развертывание

Руководство по развертыванию приложения на production.

## 📋 Требования

- VPS/Облачный сервер (AWS, DigitalOcean, Hetzner, и т.д.)
- Ubuntu 20.04+ или аналогичная ОС Linux
- Docker & Docker Compose установлены
- SSL сертификат (Let's Encrypt)
- Доменное имя

## 🔧 Подготовка сервера

```bash
# Обновить систему
sudo apt update && sudo apt upgrade -y

# Установить Docker
sudo apt install -y docker.io docker-compose

# Добавить пользователя в группу docker
sudo usermod -aG docker $USER

# Проверить установку
docker --version
docker-compose --version
```

## 📦 Развертывание Backend

### 1. Клонирование репозитория

```bash
cd /opt
sudo git clone https://github.com/yourusername/spring-hack-2026.git
sudo chown -R $USER:$USER spring-hack-2026
```

### 2. Конфигурация .env

```bash
cd backend
cp .env.example .env
nano .env
```

**Production переменные:**
```env
DEBUG=False
SECRET_KEY=your-super-secret-key-generate-this
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True

DATABASE_URL=postgresql://postgres:strong_password@db:5432/spring_hack
REDIS_HOST=redis
REDIS_PORT=6379

EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

ENVIRONMENT=production
LOG_LEVEL=WARNING
```

### 3. Docker Compose для Production

Создайте `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: spring_hack
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - backend

  redis:
    image: redis:7
    restart: unless-stopped
    networks:
      - backend

  backend:
    build:
      context: .
      dockerfile: dockerfile.prod
    environment:
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@db:5432/spring_hack
    volumes:
      - static_files:/app/staticfiles
      - media_files:/app/media
      - logs:/app/logs
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - backend
    expose:
      - "8000"

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - static_files:/var/www/staticfiles:ro
      - media_files:/var/www/media:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - backend

volumes:
  postgres_data:
  static_files:
  media_files:
  logs:

networks:
  backend:
    driver: bridge
```

### 4. Nginx конфигурация

Создайте `nginx.conf`:

```nginx
user nginx;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL конфиг
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    upstream django {
        server backend:8000;
    }

    server {
        listen 80;
        server_name yourdomain.com www.yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name yourdomain.com www.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        client_max_body_size 10M;

        location /static/ {
            alias /var/www/staticfiles/;
        }

        location /media/ {
            alias /var/www/media/;
        }

        location / {
            proxy_pass http://django;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### 5. Запуск Production контейнеров

```bash
docker-compose -f docker-compose.prod.yml up -d

# Применить миграции
docker-compose -f docker-compose.prod.yml exec backend python manage.py migrate

# Создать суперпользователя
docker-compose -f docker-compose.prod.yml exec backend python manage.py createsuperuser

# Собрать статические файлы
docker-compose -f docker-compose.prod.yml exec backend python manage.py collectstatic --noinput
```

## 🌐 SSL сертификат (Let's Encrypt)

### Получение сертификата

```bash
# Установить Certbot
sudo apt install -y certbot python3-certbot-nginx

# Получить сертификат
sudo certbot certonly \
  --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your-email@example.com \
  --agree-tos

# Сертификаты будут в /etc/letsencrypt/live/yourdomain.com/
```

### Авто-обновление

```bash
# Проверить авто-обновление
sudo systemctl start certbot.timer
sudo systemctl enable certbot.timer

# Проверить статус
sudo systemctl status certbot.timer
```

## 📱 Frontend на Vercel/Netlify

### Vercel

```bash
# Установить CLI
npm install -g vercel

# Логин
vercel login

# Деплой из entry_point папки
cd entry_point
vercel build
vercel deploy --prod
```

### Netlify

```bash
# Установить CLI
npm install -g netlify-cli

# Логин
netlify login

# Деплой
cd entry_point
netlify deploy --prod --dir=build/web
```

## 📊 Мониторинг

### Health check

```bash
# Проверить статус API
curl https://yourdomain.com/api/health/

# Проверить логи
docker-compose -f docker-compose.prod.yml logs -f backend
```

### Логирование сервера

```bash
# Просмотр логов
docker-compose -f docker-compose.prod.yml logs backend

# Логи в файл
docker-compose -f docker-compose.prod.yml logs >> backend.log
```

## 🔄 Обновления

### Обновить приложение

```bash
# Получить последние изменения
git pull origin main

# Пересобрать образы
docker-compose -f docker-compose.prod.yml build --no-cache

# Перезапустить контейнеры
docker-compose -f docker-compose.prod.yml up -d

# Применить миграции
docker-compose -f docker-compose.prod.yml exec backend python manage.py migrate
```

## 🔐 Безопасность

### Firewall настройка (UFW)

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### Backup БД

```bash
# Ручной backup
docker-compose -f docker-compose.prod.yml exec db pg_dump \
  -U postgres spring_hack > backup_$(date +%Y%m%d_%H%M%S).sql

# Автоматический backup (cron)
0 2 * * * docker-compose -f /opt/spring-hack-2026/backend/docker-compose.prod.yml exec db pg_dump -U postgres spring_hack > /backups/db_backup_$(date +\%Y\%m\%d).sql
```

### Обновление зависимостей

```bash
# Проверить устаревшие пакеты
pip list --outdated
flutter pub outdated

# Обновить
pip install -U pip
pip install --upgrade -r requirements.txt
flutter pub upgrade
```

## 🆘 Решение проблем

### Контейнер не стартует

```bash
# Проверить логи
docker logs container_name

# Проверить Healthcheck
docker inspect container_name
```

### БД недоступна

```bash
# Проверить соединение
docker-compose -f docker-compose.prod.yml exec backend python -c \
  "import psycopg2; psycopg2.connect('dbname=spring_hack user=postgres password=PASSWORD host=db')"
```

### Статические файлы не грузятся

```bash
# Пересобрать static files
docker-compose -f docker-compose.prod.yml exec backend python manage.py collectstatic --noinput

# Проверить nginx конфиг
docker exec nginx_container nginx -t
```

---

Последнее обновление: 25 марта 2026 г.
