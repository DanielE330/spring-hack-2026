import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

// ─── Biometric provider ──────────────────────────────────────────────────────

final biometricProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BiometricNotifier(prefs);
});

class BiometricState {
  const BiometricState({
    this.isEnabled = false,
    this.isAvailable = false,
    this.availableBiometrics = const [],
    this.isAuthenticated = false,
  });

  /// Пользователь включил биометрию в настройках
  final bool isEnabled;

  /// Устройство поддерживает биометрию
  final bool isAvailable;

  /// Доступные типы биометрии
  final List<BiometricType> availableBiometrics;

  /// Успешно прошёл биометрическую проверку в этой сессии
  final bool isAuthenticated;

  bool get hasFace => availableBiometrics.contains(BiometricType.face);
  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint) ||
      availableBiometrics.contains(BiometricType.strong) ||
      availableBiometrics.contains(BiometricType.weak);

  String get biometricLabel {
    if (hasFace && hasFingerprint) return 'Face ID / Отпечаток';
    if (hasFace) return 'Face ID';
    if (hasFingerprint) return 'Отпечаток пальца';
    return 'Биометрия';
  }

  BiometricState copyWith({
    bool? isEnabled,
    bool? isAvailable,
    List<BiometricType>? availableBiometrics,
    bool? isAuthenticated,
  }) =>
      BiometricState(
        isEnabled: isEnabled ?? this.isEnabled,
        isAvailable: isAvailable ?? this.isAvailable,
        availableBiometrics: availableBiometrics ?? this.availableBiometrics,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class BiometricNotifier extends StateNotifier<BiometricState> {
  BiometricNotifier(this._prefs) : super(const BiometricState()) {
    _init();
  }

  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();
  static const _kKey = 'biometric_enabled';

  Future<void> _init() async {
    final enabled = _prefs.getBool(_kKey) ?? false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      final available = canCheck || isDeviceSupported;
      final biometrics = available ? await _auth.getAvailableBiometrics() : <BiometricType>[];

      state = state.copyWith(
        isEnabled: enabled,
        isAvailable: available,
        availableBiometrics: biometrics,
        // Если биометрия отключена — считаем аутентифицированным
        isAuthenticated: !enabled,
      );
    } on PlatformException {
      state = state.copyWith(
        isEnabled: false,
        isAvailable: false,
        isAuthenticated: true,
      );
    }
  }

  /// Включить / выключить биометрию
  Future<bool> toggle(bool enable) async {
    if (enable) {
      // Сначала проверяем, что биометрия доступна
      if (!state.isAvailable) return false;

      // Просим подтвердить биометрией перед включением
      final success = await authenticate();
      if (!success) return false;

      await _prefs.setBool(_kKey, true);
      state = state.copyWith(isEnabled: true, isAuthenticated: true);
      return true;
    } else {
      await _prefs.setBool(_kKey, false);
      state = state.copyWith(isEnabled: false, isAuthenticated: true);
      return true;
    }
  }

  /// Запрос биометрической аутентификации
  Future<bool> authenticate() async {
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Подтвердите вашу личность для входа в приложение',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (success) {
        state = state.copyWith(isAuthenticated: true);
      }
      return success;
    } on PlatformException {
      return false;
    }
  }

  /// Сбросить аутентификацию (для следующего открытия)
  void resetAuth() {
    if (state.isEnabled) {
      state = state.copyWith(isAuthenticated: false);
    }
  }
}
