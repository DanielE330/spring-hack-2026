import 'package:screen_brightness/screen_brightness.dart';
import 'app_logger.dart';

const _tag = 'BrightnessHelper';

/// Сохраняет текущую яркость и устанавливает максимальную.
Future<double> setMaxBrightness() async {
  try {
    final current = await ScreenBrightness().application;
    await ScreenBrightness().setApplicationScreenBrightness(1.0);
    AppLogger.i(_tag, 'Brightness ➜ 1.0 (was $current)');
    return current;
  } catch (e) {
    AppLogger.e(_tag, 'Failed to set max brightness', error: e);
    return 0.5;
  }
}

/// Восстанавливает яркость до предыдущего значения.
Future<void> restoreBrightness(double previous) async {
  try {
    await ScreenBrightness().resetApplicationScreenBrightness();
    AppLogger.i(_tag, 'Brightness restored');
  } catch (e) {
    AppLogger.e(_tag, 'Failed to restore brightness', error: e);
  }
}
