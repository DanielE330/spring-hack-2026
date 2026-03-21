import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../utils/app_logger.dart';
import 'interceptors.dart';

class ApiClient {
  static const _tag = 'ApiClient';

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeoutMs),
        headers: {'Accept': 'application/json'},
      ),
    );

    _authInterceptor = AuthInterceptor();

    _dio.interceptors.addAll([
      _authInterceptor,
      ErrorInterceptor(),
      if (const bool.fromEnvironment('dart.vm.product') == false)
        PrettyDioLogger(requestBody: true, responseBody: true),
    ]);

    AppLogger.i(
      _tag,
      '🚀 ApiClient init baseUrl=${ApiConstants.baseUrl}',
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  Dio get dio => _dio;

  /// Set by AuthNotifier after construction to handle 401-refresh failure → logout.
  set onForceLogout(OnForceLogout? cb) => _authInterceptor.onForceLogout = cb;
}

