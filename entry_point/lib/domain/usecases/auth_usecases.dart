import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<User> call({
    required String email,
    required String password,
    String deviceName = 'unknown',
  }) =>
      _repo.login(email: email, password: password, deviceName: deviceName);
}

class GetMeUseCase {
  const GetMeUseCase(this._repo);
  final AuthRepository _repo;
  Future<User> call() => _repo.getMe();
}

class LogoutUseCase {
  const LogoutUseCase(this._repo);
  final AuthRepository _repo;
  Future<void> call() => _repo.logout();
}
