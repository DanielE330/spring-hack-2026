import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Login with email+password+device_name.
  /// Returns parsed user; tokens are saved to SecureStorage inside impl.
  Future<User> login({
    required String email,
    required String password,
    String deviceName,
  });

  /// GET /users/me/
  Future<User> getMe();

  /// POST /auth/logout/ then clear storage.
  Future<void> logout();
}
