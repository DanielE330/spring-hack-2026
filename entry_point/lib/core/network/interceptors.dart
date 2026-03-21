import 'package:dio/dio.dart';
import '../../core/errors/app_exception.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/app_logger.dart';

/// Called by [AuthInterceptor] on 401 so [AuthNotifier] can redirect to login.
typedef OnForceLogout = Future<void> Function();

const _tag = 'AuthInterceptor';

/// Adds `Authorization: Token <device_code>` to every request.
/// On 401 — clears storage and calls [onForceLogout].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.onForceLogout});

  OnForceLogout? onForceLogout;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final deviceCode = await SecureStorage.instance.getDeviceCode();

    if (deviceCode != null) {
      options.headers['Authorization'] = 'Token $deviceCode';
      AppLogger.d(_tag, '[REQ] ${options.method} ${options.path} — Token добавлен');
    } else {
      AppLogger.d(_tag, '[REQ] ${options.method} ${options.path} — без токена');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    AppLogger.w(_tag, '[ERR] ${err.requestOptions.method} ${err.requestOptions.path} → $statusCode');

    if (statusCode == 401) {
      AppLogger.e(_tag, '401 — токен недействителен, выполняю logout');
      await SecureStorage.instance.clearAll();
      await onForceLogout?.call();
    }

    handler.next(err);
  }
}

/// Maps DioException → AppException + logs every request/response.
class ErrorInterceptor extends Interceptor {
  static const _tag = 'ErrorInterceptor';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.i(_tag,
      '➡️  ${options.method} ${options.baseUrl}${options.path}'
      '${options.queryParameters.isNotEmpty ? "  q=${options.queryParameters}" : ""}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.i(_tag,
      '✅ ${response.requestOptions.method} ${response.requestOptions.path}'
      ' → ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final data = response.data;
      String message = 'Ошибка сервера';
      Map<String, List<String>>? errors;
      if (data is Map<String, dynamic>) {
        message = (data['detail'] as String?)
            ?? (data['message'] as String?)
            ?? message;
        final raw = data['errors'];
        if (raw is Map<String, dynamic>) {
          errors = raw.map<String, List<String>>(
            (k, v) => MapEntry(k, v is List ? List<String>.from(v) : [v.toString()]),
          );
        }
      }
      AppLogger.e(_tag,
        '❌ ${err.requestOptions.method} ${err.requestOptions.path}'
        ' → ${response.statusCode}: $message',
        error: err,
      );
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: AppException(
            message: message,
            statusCode: response.statusCode,
            errors: errors,
          ),
        ),
      );
      return;
    }
    AppLogger.e(_tag,
      '🌐 Сетевая ошибка: ${err.type.name} — ${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
