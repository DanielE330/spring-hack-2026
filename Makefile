# ! Makefile для удобства разработки

# Переменные
PYTHON := python3
PIP := pip3
DOCKER := docker
DOCKER_COMPOSE := docker-compose
FLUTTER := flutter

# Цвета для вывода
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help install backend-setup backend-run backend-test frontend-setup frontend-run frontend-test clean docker-up docker-down

help:
	@echo "$(BLUE)=== Spring Hack 2026 - Доступные команды ===$(NC)"
	@echo ""
	@echo "$(GREEN)Docker$(NC)"
	@echo "  make docker-up          - Запустить все контейнеры"
	@echo "  make docker-down        - Остановить контейнеры"
	@echo "  make docker-logs        - Показать логи контейнеров"
	@echo ""
	@echo "$(GREEN)Backend$(NC)"
	@echo "  make backend-setup      - Установить зависимости backend"
	@echo "  make backend-run        - Запустить backend локально"
	@echo "  make backend-test       - Запустить тесты backend"
	@echo "  make backend-migrate    - Применить миграции БД"
	@echo "  make backend-admin      - Создать суперпользователя"
	@echo ""
	@echo "$(GREEN)Frontend$(NC)"
	@echo "  make frontend-setup     - Установить зависимости frontend"
	@echo "  make frontend-run       - Запустить frontend (web)"
	@echo "  make frontend-test      - Запустить тесты frontend"
	@echo "  make frontend-build     - Собрать web версию"
	@echo ""
	@echo "$(GREEN)Утилиты$(NC)"
	@echo "  make install            - Полная установка обоих частей"
	@echo "  make lint               - Запустить линтеры"
	@echo "  make format             - Форматировать код"
	@echo "  make clean              - Очистить кеш и временные файлы"
	@echo "  make help               - Показать эту справку"

.PHONY: docker-up
docker-up:
	@echo "$(BLUE)Запуск Docker контейнеров...$(NC)"
	cd backend && $(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✓ Контейнеры запущены$(NC)"
	@echo "  Backend API: http://localhost:8000"
	@echo "  Django Admin: http://localhost:8000/admin"

.PHONY: docker-down
docker-down:
	@echo "$(BLUE)Остановка Docker контейнеров...$(NC)"
	cd backend && $(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Контейнеры остановлены$(NC)"

.PHONY: docker-logs
docker-logs:
	cd backend && $(DOCKER_COMPOSE) logs -f

.PHONY: backend-setup
backend-setup:
	@echo "$(BLUE)Установка backend зависимостей...$(NC)"
	cd backend && $(PYTHON) -m venv venv
	cd backend && . venv/bin/activate && $(PIP) install -r requirements.txt
	@echo "$(GREEN)✓ Backend установлен$(NC)"

.PHONY: backend-run
backend-run:
	@echo "$(BLUE)Запуск backend...$(NC)"
	cd backend/entry_point && $(PYTHON) manage.py runserver

.PHONY: backend-migrate
backend-migrate:
	@echo "$(BLUE)Применение миграций БД...$(NC)"
	cd backend/entry_point && $(PYTHON) manage.py migrate
	@echo "$(GREEN)✓ Миграции применены$(NC)"

.PHONY: backend-admin
backend-admin:
	@echo "$(BLUE)Создание суперпользователя...$(NC)"
	cd backend && $(PYTHON) create_admin.py
	@echo "$(GREEN)✓ Суперпользователь создан$(NC)"

.PHONY: backend-test
backend-test:
	@echo "$(BLUE)Запуск тестов backend...$(NC)"
	cd backend/entry_point && $(PYTHON) manage.py test
	@echo "$(GREEN)✓ Тесты завершены$(NC)"

.PHONY: frontend-setup
frontend-setup:
	@echo "$(BLUE)Установка frontend зависимостей...$(NC)"
	cd entry_point && $(FLUTTER) pub get
	@echo "$(GREEN)✓ Frontend установлен$(NC)"

.PHONY: frontend-run
frontend-run:
	@echo "$(BLUE)Запуск frontend (web)...$(NC)"
	cd entry_point && $(FLUTTER) run -d web-server
	@echo "$(GREEN)✓ Frontend запущен на http://localhost:3000$(NC)"

.PHONY: frontend-test
frontend-test:
	@echo "$(BLUE)Запуск тестов frontend...$(NC)"
	cd entry_point && $(FLUTTER) test
	@echo "$(GREEN)✓ Тесты завершены$(NC)"

.PHONY: frontend-build
frontend-build:
	@echo "$(BLUE)Сборка web версии...$(NC)"
	cd entry_point && $(FLUTTER) build web --release
	@echo "$(GREEN)✓ Web версия собрана в entry_point/build/web$(NC)"

.PHONY: install
install: backend-setup frontend-setup
	@echo "$(GREEN)✓ Полная установка завершена$(NC)"
	@echo "Дальше запустите:"
	@echo "  make docker-up       - для запуска через Docker"
	@echo "  make backend-run     - для локального запуска backend"
	@echo "  make frontend-run    - для запуска frontend"

.PHONY: lint
lint:
	@echo "$(BLUE)Запуск линтеров...$(NC)"
	@echo "Backend:"
	-cd backend && $(PYTHON) -m flake8 entry_point/
	@echo ""
	@echo "Frontend:"
	-cd entry_point && $(FLUTTER) analyze
	@echo "$(GREEN)✓ Линтирование завершено$(NC)"

.PHONY: format
format:
	@echo "$(BLUE)Форматирование кода...$(NC)"
	@echo "Backend (black):"
	-cd backend && $(PYTHON) -m black entry_point/
	@echo ""
	@echo "Frontend (dart format):"
	-cd entry_point && $(FLUTTER) format lib/ --set-exit-if-changed
	@echo "$(GREEN)✓ Форматирование завершено$(NC)"

.PHONY: clean
clean:
	@echo "$(BLUE)Очистка кеша и временных файлов...$(NC)"
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name ".DS_Store" -delete
	cd entry_point && $(FLUTTER) clean
	@echo "$(GREEN)✓ Очистка завершена$(NC)"

.PHONY: status
status:
	@echo "$(BLUE)Статус проекта:$(NC)"
	@echo ""
	@echo "Docker контейнеры:"
	@cd backend && $(DOCKER_COMPOSE) ps
	@echo ""
	@echo "Python версия:"
	@$(PYTHON) --version
	@echo ""
	@echo "Flutter версия:"
	@$(FLUTTER) --version
