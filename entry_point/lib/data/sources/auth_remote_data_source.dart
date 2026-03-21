import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  static const _tag = 'AuthRemoteDS';

  AuthRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    AppLogger.i(_tag, 'login → email=$email device=$deviceName');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password, 'device_name': deviceName},
    );
    AppLogger.i(_tag, 'login ✅');
    return resp.data!;
  }

  Future<UserModel> getMe() async {
    AppLogger.i(_tag, 'getMe →');
    final resp = await _dio.get<Map<String, dynamic>>(ApiConstants.me);
    final user = UserModel.fromJson(resp.data!);
    AppLogger.i(_tag, 'getMe ✅ userId=${user.id}');
    return user;
  }

  /// POST /auth/create-user/ (admin only)
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String name,
    required String surname,
    String? patronymic,
    required String password,
    bool isAdmin = false,
  }) async {
    AppLogger.i(_tag, 'createUser → email=$email');
    final body = <String, dynamic>{
      'email': email,
      'name': name,
      'surname': surname,
      'password': password,
      'is_admin': isAdmin,
    };
    if (patronymic != null && patronymic.isNotEmpty) {
      body['patronymic'] = patronymic;
    }
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.createUser,
      data: body,
    );
    AppLogger.i(_tag, 'createUser ✅');
    return resp.data!;
  }

  Future<void> logout({required String deviceCode}) async {
    AppLogger.i(_tag, 'logout →');
    await _dio.post<dynamic>(
      ApiConstants.logout,
      data: {'device_code': deviceCode},
    );
    AppLogger.i(_tag, 'logout ✅');
  }

  /// POST /auth/password-reset/
  Future<Map<String, dynamic>> requestPasswordReset({required String email}) async {
    AppLogger.i(_tag, 'requestPasswordReset → email=$email');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.passwordReset,
      data: {'email': email},
    );
    AppLogger.i(_tag, 'requestPasswordReset ✅');
    return resp.data!;
  }
}

