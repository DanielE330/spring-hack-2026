import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

/// Extracts a clean, user-friendly error message from any exception.
///
/// Handles [AppException], [DioException] (which wraps [AppException] in .error),
/// and generic exceptions. Strips technical prefixes like "AppException(400): ".
String extractErrorMessage(Object e) {
  // 1. Direct AppException
  if (e is AppException) {
    return _humanMessage(e);
  }

  // 2. DioException whose .error is AppException (from ErrorInterceptor)
  if (e is DioException) {
    final inner = e.error;
    if (inner is AppException) {
      return _humanMessage(inner);
    }
    // Network error without server response
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Превышено время ожидания. Проверьте подключение к интернету';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Нет соединения с сервером';
    }
    if (e.type == DioExceptionType.cancel) {
      return 'Запрос был отменён';
    }
    return 'Ошибка сети. Попробуйте позже';
  }

  // 3. Fallback — strip "AppException(XXX): " prefix from toString()
  final str = e.toString();
  final cleaned = _stripAppExceptionPrefix(str);
  if (cleaned.isNotEmpty) return cleaned;
  return 'Произошла непредвиденная ошибка';
}

/// Builds a human-readable message from an [AppException].
String _humanMessage(AppException e) {
  // If there are field-level validation errors, format them nicely
  if (e.errors != null && e.errors!.isNotEmpty) {
    final parts = <String>[];
    for (final entry in e.errors!.entries) {
      final field = _translateField(entry.key);
      for (final msg in entry.value) {
        parts.add('$field: ${_translateBackendMessage(msg)}');
      }
    }
    if (parts.isNotEmpty) return parts.join('\n');
  }

  // Map common status codes to friendly messages
  final msg = e.message;
  final code = e.statusCode;

  // If backend already returned a usable Russian message, use it
  if (msg.isNotEmpty && msg != 'Ошибка сервера') {
    return _translateBackendMessage(msg);
  }

  return switch (code) {
    400 => 'Некорректные данные',
    401 => 'Сессия истекла. Войдите заново',
    403 => 'Нет доступа',
    404 => 'Не найдено',
    409 => 'Конфликт данных',
    429 => 'Слишком много запросов. Подождите',
    final c? when c >= 500 && c < 600 => 'Ошибка сервера. Попробуйте позже',
    _ => msg.isNotEmpty ? msg : 'Произошла непредвиденная ошибка',
  };
}

/// Translates common backend field names to Russian.
String _translateField(String field) {
  return switch (field) {
    'email' => 'Email',
    'password' => 'Пароль',
    'name' => 'Имя',
    'surname' => 'Фамилия',
    'patronymic' => 'Отчество',
    'device_name' => 'Устройство',
    'non_field_errors' => 'Ошибка',
    'detail' => 'Ошибка',
    _ => field,
  };
}

/// Translates common English backend messages to Russian.
String _translateBackendMessage(String msg) {
  final lower = msg.toLowerCase();
  if (lower.contains('user with this email already exists')) {
    return 'Пользователь с таким email уже существует';
  }
  if (lower.contains('no active account') ||
      lower.contains('unable to log in with provided credentials') ||
      lower.contains('invalid credentials')) {
    return 'Неверный email или пароль';
  }
  if (lower.contains('token') && lower.contains('invalid')) {
    return 'Сессия истекла. Войдите заново';
  }
  if (lower.contains('not found')) {
    return 'Не найдено';
  }
  if (lower.contains('permission denied') || lower.contains('forbidden')) {
    return 'Нет доступа';
  }
  if (lower.contains('this field may not be blank')) {
    return 'Это поле не может быть пустым';
  }
  if (lower.contains('this field is required')) {
    return 'Это поле обязательно';
  }
  if (lower.contains('ensure this value has at least')) {
    return 'Слишком короткое значение';
  }
  if (lower.contains('enter a valid email')) {
    return 'Введите корректный email';
  }
  return msg;
}

/// Strips "AppException(XXX): " prefix from toString() output.
String _stripAppExceptionPrefix(String s) {
  // e.g. "AppException(400): Неверные данные" → "Неверные данные"
  final re = RegExp(r'^AppException\(\d*\):\s*');
  final stripped = s.replaceFirst(re, '').trim();
  // Also strip "Exception: " etc.
  final re2 = RegExp(r'^(Exception|Error):\s*');
  return stripped.replaceFirst(re2, '').trim();
}
