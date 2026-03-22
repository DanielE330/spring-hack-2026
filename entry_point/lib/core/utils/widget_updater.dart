import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';

const _channel = MethodChannel('com.example.entry_point/widget');
const _tag = 'WidgetUpdater';

/// Принудительно обновляет Android Home Screen Widget с QR-пропуском.
Future<void> updateHomeWidget() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _channel.invokeMethod('updateWidget');
    AppLogger.d(_tag, 'Home widget updated');
  } catch (e) {
    AppLogger.e(_tag, 'Failed to update home widget', error: e);
  }
}
