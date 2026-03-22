import '../../core/storage/secure_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/widget_updater.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _tag = 'AuthRepository';

  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;

  @override
  Future<User> login({
    required String email,
    required String password,
    String deviceName = 'unknown',
  }) async {
    AppLogger.i(_tag, 'login() → email=$email');
    try {
      final data = await _remote.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );

      // Backend returns: {id, name, surname, email, device_code, is_admin}
      final deviceCode = (data['device_code'] ?? '').toString();

      await Future.wait([
        _storage.saveDeviceCode(deviceCode),
        _storage.saveIsAdmin((data['is_admin'] as bool?) ?? false),
      ]);

      final userMap = data.containsKey('user')
          ? data['user'] as Map<String, dynamic>
          : data;
      final user = UserModel.fromJson(userMap).toEntity();

      AppLogger.i(_tag, 'login() ✅ userId=${user.id} isAdmin=${user.isAdmin}');

      // Обновляем виджет на рабочем столе, чтобы он подхватил device_code
      updateHomeWidget();

      return user;
    } catch (e, st) {
      AppLogger.e(_tag, 'login() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<User> getMe() async {
    AppLogger.i(_tag, 'getMe()');
    try {
      final model = await _remote.getMe();
      AppLogger.i(_tag, 'getMe() ✅ userId=${model.id}');
      return model.toEntity();
    } catch (e, st) {
      AppLogger.e(_tag, 'getMe() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    AppLogger.i(_tag, 'logout()');
    try {
      final deviceCode = await _storage.getDeviceCode() ?? '';
      await _remote.logout(deviceCode: deviceCode);
    } catch (e) {
      AppLogger.w(_tag, 'logout() remote call failed (ignoring): $e');
    } finally {
      await _storage.clearAll();
      AppLogger.i(_tag, 'logout() ✅ storage cleared');
      updateHomeWidget();
    }
  }
  // --- end of AuthRepositoryImpl ---
}
