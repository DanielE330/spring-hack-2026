#!/bin/bash

#######################################
# Flutter Multi-Platform Build Script
# Построение для всех платформ
#######################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Функции для проверки зависимостей
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter не установлен!"
        print_info "Установите Flutter: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
}

check_android_sdk() {
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        print_error "Android SDK не найден (ANDROID_SDK_ROOT или ANDROID_HOME не установлены)"
        return 1
    fi
    return 0
}

# Функции для сборки
build_web() {
    print_header "Сборка для Web"
    
    print_info "Выполняю: flutter build web --release"
    flutter build web --release
    
    if [ -d "build/web" ]; then
        mkdir -p ../release/web
        cp -r build/web/* ../release/web/
        print_success "Web сборка завершена!"
        print_info "Файлы находятся в: ../release/web/"
        return 0
    fi
    return 1
}

build_android() {
    print_header "Сборка для Android"
    
    if ! check_android_sdk; then
        print_error "Пропуск Android сборки - Android SDK не найден"
        return 1
    fi
    
    print_info "Выполняю: flutter build apk --release"
    flutter build apk --release
    
    print_info "Выполняю: flutter build appbundle --release"
    flutter build appbundle --release
    
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        mkdir -p ../release/android
        cp build/app/outputs/flutter-apk/app-release.apk ../release/android/app-release.apk
        
        if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
            cp build/app/outputs/bundle/release/app-release.aab ../release/android/app-release.aab
        fi
        
        print_success "Android сборка завершена!"
        print_info "Файлы находятся в: ../release/android/"
        print_info "  - app-release.apk (для установки на устройство)"
        print_info "  - app-release.aab (для Google Play Store)"
        return 0
    fi
    return 1
}

build_linux() {
    print_header "Сборка для Linux"
    
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Linux сборка должна выполняться на Linux (текущая ОС: $OSTYPE)"
        return 1
    fi
    
    if ! command -v cmake &> /dev/null; then
        print_error "CMake не найден. Установите: sudo apt install cmake"
        return 1
    fi
    
    print_info "Выполняю: flutter build linux --release"
    flutter build linux --release
    
    if [ -d "build/linux/x64/release/bundle" ]; then
        mkdir -p ../release/linux
        cp -r build/linux/x64/release/bundle/* ../release/linux/
        print_success "Linux сборка завершена!"
        print_info "Файлы находятся в: ../release/linux/"
        print_info "Запуск: ../release/linux/spring_hawk_2026"
        return 0
    fi
    return 1
}

build_windows() {
    print_header "Сборка для Windows"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v wine &> /dev/null; then
            print_warning "Обнаружена Windows ОС на Linux (Wine установлен)"
            print_info "Выполняю сборку через Windows SDK..."
        else
            print_error "Wine не найден на Ubuntu. Установите: sudo apt install wine"
            print_info "Или используйте GitHub Actions для облачной сборки Windows"
            return 1
        fi
    fi
    
    print_info "Выполняю: flutter build windows --release"
    flutter build windows --release
    
    if [ -d "build/windows/x64/runner/Release" ]; then
        mkdir -p ../release/windows
        cp -r build/windows/x64/runner/Release/* ../release/windows/
        print_success "Windows сборка завершена!"
        print_info "Файлы находятся в: ../release/windows/"
        print_info "Основной файл: ../release/windows/spring_hawk_2026.exe"
        return 0
    fi
    return 1
}

build_macos() {
    print_header "Сборка для macOS"
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "macOS сборка должна выполняться на macOS (текущая ОС: $OSTYPE)"
        return 1
    fi
    
    print_info "Выполняю: flutter build macos --release"
    flutter build macos --release
    
    if [ -d "build/macos/Build/Products/Release" ]; then
        mkdir -p ../release/macos
        cp -r build/macos/Build/Products/Release/spring_hawk_2026.app ../release/macos/
        print_success "macOS сборка завершена!"
        print_info "Файлы находятся в: ../release/macos/"
        return 0
    fi
    return 1
}

build_ios() {
    print_header "Сборка для iOS"
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "iOS сборка должна выполняться на macOS (текущая ОС: $OSTYPE)"
        return 1
    fi
    
    print_info "Выполняю: flutter build ipa --release"
    flutter build ipa --release
    
    if [ -d "build/ios/ipa" ]; then
        mkdir -p ../release/ios
        cp build/ios/ipa/*.ipa ../release/ios/ 2>/dev/null || true
        print_success "iOS сборка завершена!"
        print_info "Файлы находятся в: ../release/ios/"
        return 0
    fi
    return 1
}

# Новое приложение на pubspec.yaml
check_pubspec() {
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml не найден!"
        print_info "Запустите скрипт из папки entry_point"
        exit 1
    fi
}

# Главное меню
show_menu() {
    echo ""
    print_header "Многоплатформенная сборка Flutter"
    echo ""
    echo "Выберите платформу(ы) для сборки:"
    echo ""
    echo "  1) Web"
    echo "  2) Android (APK + AAB)"
    echo "  3) Linux"
    echo "  4) Windows"
    echo "  5) macOS"
    echo "  6) iOS"
    echo ""
    echo "  7) Все платформы (для текущей ОС)"
    echo "  8) Веб + Linux (рекомендуется на Ubuntu)"
    echo "  9) Веб + Linux + Windows (для Ubuntu с Wine)"
    echo ""
    echo "  0) Выход"
    echo ""
}

# Очистка кеша
clean_cache() {
    print_info "Очистка Flutter кеша..."
    flutter clean
    print_success "Кеш очищен"
}

# Получение публик зависимостей
get_dependencies() {
    print_info "Получение зависимостей..."
    flutter pub get
    print_success "Зависимости загружены"
}

# Основная логика
main() {
    check_pubspec
    check_flutter
    
    print_header "Flutter Build Assistant"
    
    # Опционально: очистить кеш
    echo ""
    read -p "Очистить Flutter кеш перед сборкой? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean_cache
    fi
    
    get_dependencies
    
    while true; do
        show_menu
        read -p "Введите номер (0-9): " choice
        
        case $choice in
            1)
                build_web || print_error "Web сборка не удалась"
                ;;
            2)
                build_android || print_error "Android сборка не удалась"
                ;;
            3)
                build_linux || print_error "Linux сборка не удалась"
                ;;
            4)
                build_windows || print_error "Windows сборка не удалась"
                ;;
            5)
                build_macos || print_error "macOS сборка не удалась"
                ;;
            6)
                build_ios || print_error "iOS сборка не удалась"
                ;;
            7)
                print_info "Сборка для всех доступных платформ на текущей ОС..."
                build_web || print_error "Web сборка не удалась"
                build_android || true
                build_linux || true
                build_macos || true
                build_ios || true
                ;;
            8)
                print_info "Сборка Веб + Linux..."
                build_web || print_error "Web сборка не удалась"
                build_linux || print_error "Linux сборка не удалась"
                ;;
            9)
                print_info "Сборка Веб + Linux + Windows..."
                build_web || print_error "Web сборка не удалась"
                build_linux || print_error "Linux сборка не удалась"
                build_windows || print_error "Windows сборка не удалась"
                ;;
            0)
                print_info "Выход"
                exit 0
                ;;
            *)
                print_error "Неправильный выбор. Выберите 0-9"
                ;;
        esac
        
        echo ""
        read -p "Нажмите Enter для продолжения..."
    done
}

# Запуск
if [ "$1" != "" ]; then
    print_error "Использование: $0"
    print_info "Скрипт запускает интерактивное меню выбора платформ"
    exit 1
fi

main
