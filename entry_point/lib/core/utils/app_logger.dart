import 'dart:developer' as dev;

/// Centralized logger. All output goes to the Dart VM log (visible in
/// Flutter DevTools → Logging tab and in the `flutter run` console).
///
/// Usage:
///   AppLogger.i('TAG', 'message');
///   AppLogger.e('TAG', 'message', error: e, stackTrace: st);
class AppLogger {
  AppLogger._();

  // Dart log levels (mirrors java.util.logging.Level)
  static const int _kFine = 500;
  static const int _kInfo = 800;
  static const int _kWarning = 900;
  static const int _kSevere = 1000;

  /// Debug / verbose
  static void d(String tag, String message) {
    dev.log(
      '🔍 $message',
      name: tag,
      level: _kFine,
    );
  }

  /// Informational
  static void i(String tag, String message) {
    dev.log(
      'ℹ️  $message',
      name: tag,
      level: _kInfo,
    );
  }

  /// Warning
  static void w(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      '⚠️  $message',
      name: tag,
      level: _kWarning,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error / severe
  static void e(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '❌ $message',
      name: tag,
      level: _kSevere,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Navigation event
  static void nav(String from, String to) {
    dev.log(
      '🧭 $from → $to',
      name: 'Router',
      level: _kInfo,
    );
  }

  /// Prints a horizontal separator for readability
  static void separator(String tag) {
    dev.log('─' * 60, name: tag, level: _kFine);
  }
}
