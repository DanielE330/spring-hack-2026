import 'dart:io';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.example.entry_point/screen');

/// Запрет скриншотов на Android через FLAG_SECURE.
Future<void> enableScreenProtection() async {
  if (Platform.isAndroid) {
    try {
      await _channel.invokeMethod('setSecure', true);
    } catch (_) {}
  }
}

Future<void> disableScreenProtection() async {
  if (Platform.isAndroid) {
    try {
      await _channel.invokeMethod('setSecure', false);
    } catch (_) {}
  }
}
