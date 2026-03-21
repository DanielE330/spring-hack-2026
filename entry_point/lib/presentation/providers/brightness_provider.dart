import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

/// Настройка: увеличивать яркость при показе QR-кода.
final qrBrightnessEnabledProvider =
    StateNotifierProvider<QrBrightnessNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QrBrightnessNotifier(prefs);
});

class QrBrightnessNotifier extends StateNotifier<bool> {
  QrBrightnessNotifier(this._prefs)
      : super(_prefs.getBool(_kKey) ?? true);

  final SharedPreferences _prefs;
  static const _kKey = 'qr_auto_brightness';

  Future<void> toggle(bool value) async {
    state = value;
    await _prefs.setBool(_kKey, value);
  }
}
