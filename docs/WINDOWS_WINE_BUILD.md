# Сборка для Windows на Ubuntu (с использованием Wine)

Если вы работаете на Ubuntu/Linux, вы можете собирать Windows версию с помощью Wine.

## 🍷 Установка Wine

```bash
# Обновить репозитории
sudo apt update

# Установить Wine для 64-bit
sudo apt install -y wine wine64 wine32

# Или для более новых версий (из WineHQ репозитория)
sudo dpkg --add-architecture i386
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ focal main"
sudo apt update
sudo apt install --install-recommends winehq-stable
```

## ✓ Проверка установки

```bash
# Проверить версию Wine
wine --version
wine64 --version

# Пример вывода: wine-8.0 (Ubuntu 8.0-0ubuntu1~focal)
```

## 🔨 Сборка Flutter приложения для Windows

### Способ 1: Через Makefile

```bash
# Самый простой способ
make build-windows

# Или вручную
cd entry_point
./build_specific.sh windows
```

### Способ 2: Прямо через Flutter

```bash
cd entry_point

# Сначала проверить, что Flutter видит все зависимости
flutter doctor -v

# Построить Windows EXE
flutter build windows --release
```

### Способ 3: Через Wine эмуляцию (экспериментально)

```bash
# Требуется установить .NET Framework через winetricks
sudo apt install winetricks

# Установить необходимые компоненты для Windows сборки
winetricks dotnet48

# Затем запустить сборку
cd entry_point
flutter build windows --release
```

## 📦 Результаты сборки

После успешной сборки файлы находятся в:

```
entry_point/build/windows/x64/runner/Release/
├── spring_hawk_2026.exe           # Основной исполняемый файл
├── *.dll                          # Необходимые библиотеки
└── data/                          # Ресурсы приложения
```

Все файлы скопируются в `release/windows/`

## 🏃 Запуск скомпилированного приложения

### На Linux с Wine

```bash
# Запустить напрямую
wine64 release/windows/spring_hawk_2026.exe

# Или установить как приложение
wine64 release/windows/spring_hawk_setup.exe
```

### На Windows

Просто скачать и запустить `spring_hawk_2026.exe`

## ⚠️ Возможные проблемы

### Ошибка: "Wine не найден"

```bash
# Проверить установку
which wine wine64

# Если не найдено, переустановить
sudo apt purge wine*
sudo apt install wine64
```

### Flutter не видит Visual Studio Tools

```bash
# Flutter может работать без Visual C++ Build Tools при сборке
# Но для оптимальной сборки требуется:
# - Visual Studio Build Tools
# - Или скачать готовый WinSDK

# Временный workaround:
flutter config --no-enable-windows
flutter config --enable-windows

# Проверить статус
flutter doctor -v
```

### CMake ошибка при сборке

```bash
# Установить CMake
sudo apt install cmake

# Очистить кеш Flutter
cd entry_point
flutter clean

# Пересобрать
flutter build windows --release
```

### Бинарные файлы недоступны через Wine

В этом случае нужна настоящая Windows машина или облако (например, AppVeyor для CI/CD).

## 🔄 Автоматизация через CI/CD

Используйте GitHub Actions для автоматической сборки на облачной Windows машине:

```yaml
# .github/workflows/build-windows.yml
name: Build Windows

on: [push]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
        working-directory: entry_point
      - run: flutter build windows --release
        working-directory: entry_point
      - uses: softprops/action-gh-release@v1
        with:
          files: entry_point/build/windows/x64/runner/Release/spring_hawk_2026.exe
```

## 📱 Альтернативные варианты сборки

Если Windows сборка не работает на Ubuntu:

1. **Используйте Vercel/Netlify** — собирают Web версию на облаке
2. **AppVeyor** — облачный CI/CD для Windows сборок
3. **GitHub Actions** — виртуальные машины Windows для сборки
4. **Винтуальная машина** — установить Windows на виртуальную машину
5. **WSL 2** — Windows Subsystem for Linux с графическим интерфейсом

## 📞 Помощь

- 📖 [Flutter Windows Build Documentation](https://flutter.dev/docs/deployment/windows)
- 🍷 [Wine Documentation](https://wiki.winehq.org/)
- 🐛 [Issues](../../issues)

---

Последнее обновление: 25 марта 2026 г.
