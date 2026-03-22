import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/error_helpers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/sources/auth_remote_data_source.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ─── DI providers ─────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (_) => AuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    SecureStorage.instance,
  );
});

final loginUseCaseProvider  = Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final getMeUseCaseProvider  = Provider((ref) => GetMeUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider = Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));

// ─── AuthState ────────────────────────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── AuthNotifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  static const _tag = 'AuthNotifier';

  AuthNotifier(this._login, this._getMe, this._logout)
      : super(const AuthState()) {
    // Wire force-logout callback so the interceptor can call it on 401.
    ApiClient.instance.onForceLogout = _onForceLogout;
  }

  final LoginUseCase  _login;
  final GetMeUseCase  _getMe;
  final LogoutUseCase _logout;

  Future<void> _onForceLogout() async {
    AppLogger.w(_tag, 'Force logout from interceptor');
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called on Splash screen start.
  Future<void> init() async {
    AppLogger.i(_tag, 'init()');
    final deviceCode = await SecureStorage.instance.getDeviceCode();
    if (deviceCode == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      AppLogger.i(_tag, 'init() → unauthenticated (no device_code)');
      return;
    }
    // Try to load user from /users/me/
    try {
      final user = await _getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      AppLogger.i(_tag, 'init() ✅ userId=${user.id} isAdmin=${user.isAdmin}');
    } catch (e) {
      AppLogger.w(_tag, 'init() getMe failed: $e');
      // Device code exists but /users/me/ failed — treat as unauthenticated
      await SecureStorage.instance.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    AppLogger.i(_tag, 'login() email=$email');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final deviceName = kIsWeb
          ? 'web'
          : defaultTargetPlatform.toString().replaceAll('TargetPlatform.', '');
      final user = await _login(email: email, password: password, deviceName: deviceName);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      AppLogger.i(_tag, 'login() ✅ userId=${user.id} isAdmin=${user.isAdmin}');
      return true;
    } catch (e, st) {
      AppLogger.e(_tag, 'login() ❌', error: e, stackTrace: st);
      state = state.copyWith(
        error: extractErrorMessage(e),
        isLoading: false,
        status: AuthStatus.unauthenticated,
      );
      return false;
    }
  }

  Future<void> logout() async {
    AppLogger.i(_tag, 'logout()');
    state = state.copyWith(isLoading: true);
    try {
      await _logout();
    } finally {
      AppLogger.i(_tag, 'logout() ✅ → unauthenticated');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(loginUseCaseProvider),
    ref.watch(getMeUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
  );
});
