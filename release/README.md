# 📦 Release — Готовые исполняемые файлы

Эта папка содержит готовые скомпилированные версии приложения для всех платформ.

## 🗂️ Структура

```
release/
├── android/            # APK и AAB для Android
│   ├── app-release.apk
│   └── app-release.aab
├── ios/                # IPA для iOS (требуется macOS)
│   └── Spring_Hack_2026.ipa
├── linux/              # AppImage для Linux
│   └── spring_hack_2026-x86_64.AppImage
├── windows/            # EXE инсталлятор для Windows
│   └── spring_hack_setup.exe
├── macos/              # DMG / APP для macOS
│   └── spring_hack_2026.dmg
├── web/                # Скомпилированная веб-версия
│   └── index.html (+ всё содержимое)
└── README.md           # Этот файл
```

## 📥 Скачивание готовых сборок

### 🤖 Android

**Файлы:**
- `app-release.apk` — приложение для установки (полная версия)
- `app-release.aab` — Android App Bundle для Google Play

**Установка на устройство:**
```bash
adb install release/android/app-release.apk
```

**Требования:**
- Android 5.0 (API 21) и выше

### 🍎 iOS

**Файл:** `Spring_Hack_2026.ipa`

**Установка:**
- Через Xcode: `File → Open → select .ipa`
- Через Finder: перетащить на устройство

**Требования:**
- iOS 11.0 и выше
- Требуется Apple Developer аккаунт (или TestFlight)

### 🐧 Linux

**Файл:** `spring_hack_2026-x86_64.AppImage`

**Установка:**
```bash
# Сделать исполняемым
chmod +x release/linux/spring_hack_2026-x86_64.AppImage

# Запустить
./release/linux/spring_hack_2026-x86_64.AppImage
```

**Требования:**
- Ubuntu 20.04+ или аналогичная ОС
- GLIBC 2.29+

### 🪟 Windows

**Файл:** `spring_hack_setup.exe`

**Установка:**
1. Скачать `spring_hack_setup.exe`
2. Дважды нажать на файл
3. Следовать инструкциям инсталлятора
4. Приложение установится в `Program Files`

**Требования:**
- Windows 10 или выше

**Запуск через Wine (Ubuntu с Wine):**
```bash
wine64 release/windows/spring_hack_setup.exe
```

### 🖥️ macOS

**Файл:** `spring_hack_2026.dmg`

**Установка:**
1. Скачать `.dmg` файл
2. Дважды нажать для монтирования
3. Перетащить Spring Hack в Applications
4. Запустить из Applications

**Требования:**
- macOS 10.15 (Catalina) и выше

### 🌐 Web

**Папка:** `web/`

**Развертывание:**

```bash
# На локальном сервере
python3 -m http.server 3000 --directory release/web/

# Доступно на http://localhost:3000
```

**Или на облачном хостинге:**

```bash
# Vercel
vercel release/web/

# Netlify
netlify deploy --prod --dir release/web/

# GitHub Pages
# Просто загрузить содержимое папки web/ в gh-pages branch
```

## 🔨 Собрать из источников

### Все платформы

```bash
cd entry_point
./build_all.sh
```

### Конкретная платформа

```bash
cd entry_point
./build_specific.sh <platform>

# Примеры:
./build_specific.sh android
./build_specific.sh linux
./build_specific.sh windows
./build_specific.sh web
# и т.д.
```

## 🛠 Требования для сборки

### Обязательные

- **Flutter SDK 3.0+**
- **Dart SDK 3.0+**
- **Git**

### По платформам

#### Android
```bash
sudo apt install -y openjdk-11-jdk-headless
# Скачать Android SDK из https://developer.android.com/studio
# Установить через `flutter doctor`
```

#### iOS (только macOS)
```bash
xcode-select --install
```

#### Linux
```bash
sudo apt install -y cmake ninja-build pkg-config libgtk-3-dev libblkid-dev
```

#### Windows
```bash
# Visual C++ Build Tools
# Или Visual Studio Community с Desktop development C++
```

#### Windows через Wine (Ubuntu)
```bash
# Установить Wine
sudo apt install -y wine wine32 wine64 winetricks

# Требуется .NET Framework (опционально)
winetricks dotnet48
```

#### macOS (только на macOS)
```bash
brew install cocoapods
```

#### Web
Встроено в Flutter, не требует дополнительных зависимостей

## 📊 Размеры файлов

| Платформа | Тип | Примерный размер |
|-----------|-----|------------------|
| Android | APK | 40-60 MB |
| Android | AAB | 30-40 MB |
| iOS | IPA | 70-90 MB |
| Linux | AppImage | 100-150 MB |
| Windows | EXE | 120-180 MB |
| macOS | DMG | 150-200 MB |
| Web | ZIP | 15-25 MB |

## 🔐 Безопасность

### Подписание сборок

#### Android

```bash
# Создать ключ (один раз)
keytool -genkey -v -keystore ~/spring_hack.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias spring_hack

# Подписать APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/spring_hack.jks \
  app-release-unsigned.apk spring_hack

# Оптимизировать
zipalign -v 4 app-release-unsigned.apk app-release.apk
```

#### Windows (через signtool)

```bash
signtool sign /f certificate.pfx /p password \
  /t http://timestamp.server.com \
  spring_hack_setup.exe
```

## 🚀 CI/CD Deploy

Автоматический deploy в каждый релиз:

```yaml
# .github/workflows/release.yml
on:
  push:
    tags:
      - 'v*'

jobs:
  build-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --split-per-abi
      - run: flutter build web
      - uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/apk/release/app-*.apk
```

## 📝 Версионирование

Версия указывается в `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Формат: `major.minor.patch+buildNumber`

## 🔄 Update распространение

### Android
- Google Play: загрузить `.aab` в Play Console
- F-Droid: push на официальный репозиторий
- Direct: раздавать `.apk` ссылкой

### iOS
- Apple App Store: загрузить через Xcode/Transporter
- TestFlight: раздавать через TestFlight ссылку
- Direct: не возможно (требуется App Store)

### Windows
- Microsoft Store: загрузить `.msix`
- Chocolatey: создать пакет
- Direct: раздавать `.exe`

### macOS
- Mac App Store: загрузить через App Store Connect
- Homebrew: добавить в tap
- Direct: раздавать `.dmg`

### Linux
- Snap Store: `snap build && snap push`
- Flathub: создать manifest
- AUR: создать PKGBUILD
- Direct: раздавать `.AppImage`

### Web
- Vercel: `vercel --prod`
- Netlify: `netlify deploy --prod`
- GitHub Pages: `gh deploy`

## 🐛 Решение проблем

### Ошибка при сборке Android
```bash
# Очистить кеш
flutter clean
cd android && ./gradlew clean cd ..

# Пересобрать
flutter build apk --release
```

### Ошибка при сборке iOS
```bash
# Очистить
flutter clean
sudo rm -rf build

# Пересобрать
flutter build ios --release
```

### Ошибка компиляции Windows
```bash
# Убедиться что Visual Studio build tools установлены
flutter doctor -v

# Пересобрать
flutter build windows --release
```

### Проблема с Wine (Windows на Linux)
```bash
# Проверить установку Wine
wine --version

# Очистить Wine префикс
rm -rf ~/.wine

# Переинициализировать
winecfg
```

## 📞 Поддержка

За помощью:
- 📖 [Flutter Building & Release](https://flutter.dev/docs/deployment/release)
- 🐛 [Issues](../../issues)
- 💬 [Discussions](../../discussions)

---

Последнее обновление: 25 марта 2026 г.
