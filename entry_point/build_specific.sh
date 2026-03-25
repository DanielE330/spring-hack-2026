#!/bin/bash

#######################################
# Flutter Single Platform Build Script
# Сборка для конкретной платформы
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

#检查 pubspec.yaml
check_pubspec() {
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml не найден!"
        print_info "Запустите скрипт из папки entry_point"
        exit 1
    fi
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
        print_warning "Android SDK не найден (ANDROID_SDK_ROOT или ANDROID_HOME не установлены)"
        return 1
    fi
    return 0
}

# Функции для сборки
build_web() {
    print_header "Сборка для Web"
    
    print_info "Проверка зависимостей..."
    flutter pub get
    
    print_info "Выполняю: flutter build web --release"
    flutter build web --release
    
    if [ -d "build/web" ]; then
        mkdir -p ../release/web
        cp -r build/web/* ../release/web/
        print_success "Web сборка завершена!"
        print_info "Файлы находятся в: ../release/web/"
        print_info "Открыть в браузере: file://$(pwd)/../release/web/index.html"
        return 0
    else
        print_error "Web сборка завершилась с ошибкой"
        return 1
    fi
}

build_android() {
    print_header "Сборка для Android"
    
    print_info "Проверка зависимостей..."
    flutter pub get
    
    if ! check_android_sdk; then
        print_error "Пропуск Android сборки - Android SDK не найден"
        print_info "Установите Android SDK: https://flutter.dev/docs/get-started/install/linux#android-setup"
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
        print_info "APK: ../release/android/app-release.apk"
        print_info "AAB: ../release/android/app-release.aab"
        print_info "Установить на устройство: adb install ../release/android/app-release.apk"
        return 0
    else
        print_error "Android сборка завершилась с ошибкой"
        return 1
    fi
}

build_linux() {
    print_header "Сборка для Linux"
    
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Linux сборка должна выполняться на Linux"
        print_warning "Текущая ОС: $OSTYPE"
        return 1
    fi
    
    if ! command -v cmake &> /dev/null; then
        print_error "CMake не найден"
        print_info "Установите: sudo apt install cmake pkg-config libgtk-3-dev"
        return 1
    fi
    
    print_info "Проверка зависимостей..."
    flutter pub get
    
    print_info "Выполняю: flutter build linux --release"
    flutter build linux --release
    
    if [ -d "build/linux/x64/release/bundle" ]; then
        mkdir -p ../release/linux
        cp -r build/linux/x64/release/bundle/* ../release/linux/
        
        # Сделать бинарник исполняемым
        chmod +x ../release/linux/spring_hawk_2026
        
        print_success "Linux сборка завершена!"
        print_info "Файлы: ../release/linux/"
        print_info "Запуск: ./release/linux/spring_hawk_2026"
        return 0
    else
        print_error "Linux сборка завершилась с ошибкой"
        return 1
    fi
}

build_windows() {
    print_header "Сборка для Windows"
    
    print_info "Проверка зависимостей..."
    flutter pub get
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! command -v wine64 &> /dev/null; then
            print_error "Wine64 не найден на Ubuntu"
            print_info "Установите: sudo apt install wine wine32 wine64"
            print_info "Или используйте GitHub Actions для облачной Windows сборки"
            return 1
        fi
        print_warning "Обнаружена Ubuntu/Linux с Wine - сборка будет выполнена"
    elif [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "cygwin" ]] && [[ "$OSTYPE" != "win32" ]]; then
        print_warning "Эта система не Windows (текущая: $OSTYPE)"
        print_info "Можете использовать GitHub Actions для облачной сборки"
    fi
    
    print_info "Выполняю: flutter build windows --release"
    flutter build windows --release
    
    if [ -d "build/windows/x64/runner/Release" ]; then
        mkdir -p ../release/windows
        cp -r build/windows/x64/runner/Release/* ../release/windows/
        
        # Сделать бинарник исполняемым (если на Linux)
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            chmod +x ../release/windows/*.exe
        fi
        
        print_success "Windows сборка завершена!"
        print_info "Файлы: ../release/windows/"
        print_info "Основной файл: spring_hawk_2026.exe"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            print_info "Запуск на Linux: wine64 ./release/windows/spring_hawk_2026.exe"
        fi
        return 0
    else
        print_error "Windows сборка завершилась с ошибкой"
        return 1
    fi
}

build_macos() {
    print_header "Сборка для macOS"
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "macOS сборка должна выполняться на macOS"
        print_warning "Текущая ОС: $OSTYPE"
        return 1
    fi
    
    print_info "Проверка зависимостей..."
    flutter pub get
    
    print_info "Выполняю: flutter build macos --release"
    flutter build macos --release
    
    if [ -d "build/macos/Build/Products/Release" ]; then
        mkdir -p ../release/macos
        cp -r build/macos/Build/Products/Release/spring_hawk_2026.app ../release/macos/
        print_success "macOS сборка завершена!"
        print_info "Файлы: ../release/macos/spring_hawk_2026.app"
        print_info "Открыть Finder: open ../release/macos"
        return 0
    else
        print_error "macOS сборка завершилась с ошибкой"
        return 1
    fi
}

build_ios() {
    print_header "Сборка для iOS"
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "iOS сборка должна выполняться на macOS"
        print_warning "Текущая ОС: $OSTYPE"
        return 1
    fi
    
    print_info "Проверка зависимостей..."
    flutter pub get
    
    print_info "Выполняю: flutter build ipa --release"
    flutter build ipa --release
    
    if [ -d "build/ios/ipa" ]; then
        mkdir -p ../release/ios
        cp build/ios/ipa/*.ipa ../release/ios/ 2>/dev/null || true
        print_success "iOS сборка завершена!"
        print_info "Файлы: ../release/ios/"
        return 0
    else
        print_error "iOS сборка завершилась с ошибкой"
        return 1
    fi
}

# Вывод справки
print_usage() {
    print_header "Использование"
    echo ""
    echo "Синтаксис: $0 <platform>"
    echo ""
    echo "Доступные платформы:"
    echo "  web        - Web приложение (HTML/JS/CSS)"
    echo "  android    - Android (APK + AAB)"
    echo "  linux      - Linux (ELF binary)"
    echo "  windows    - Windows (EXE)"
    echo "  macos      - macOS (APP bundle) — требуется macOS"
    echo "  ios        - iOS (IPA) — требуется macOS"
    echo ""
    echo "Примеры:"
    echo "  $0 web"
    echo "  $0 android"
    echo "  $0 linux"
    echo ""
}

# Главная функция
main() {
    if [ $# -eq 0 ]; then
        print_error "Не указана платформа!"
        echo ""
        print_usage
        exit 1
    fi
    
    check_pubspec
    check_flutter
    
    local platform="$1"
    
    case "$platform" in
        web)
            build_web
            exit $?
            ;;
        android)
            build_android
            exit $?
            ;;
        linux)
            build_linux
            exit $?
            ;;
        windows)
            build_windows
            exit $?
            ;;
        macos)
            build_macos
            exit $?
            ;;
        ios)
            build_ios
            exit $?
            ;;
        *)
            print_error "Неизвестная платформа: $platform"
            echo ""
            print_usage
            exit 1
            ;;
    esac
}

# Запуск
main "$@"
