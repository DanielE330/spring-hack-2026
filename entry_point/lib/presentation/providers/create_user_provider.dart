import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/sources/auth_remote_data_source.dart';
import 'auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CreateUserState {
  const CreateUserState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final String? error;
  final String? successMessage;

  CreateUserState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      CreateUserState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CreateUserNotifier extends StateNotifier<CreateUserState> {
  static const _tag = 'CreateUserNotifier';

  CreateUserNotifier(this._remote) : super(const CreateUserState());

  final AuthRemoteDataSource _remote;

  Future<bool> createUser({
    required String email,
    required String name,
    required String surname,
    String? patronymic,
    required String password,
    bool isAdmin = false,
  }) async {
    AppLogger.i(_tag, 'createUser() email=$email');
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final data = await _remote.createUser(
        email: email,
        name: name,
        surname: surname,
        patronymic: patronymic,
        password: password,
        isAdmin: isAdmin,
      );
      final msg = (data['message'] as String?) ?? 'Пользователь создан';
      state = state.copyWith(isLoading: false, successMessage: msg);
      AppLogger.i(_tag, 'createUser() ✅ $msg');
      return true;
    } catch (e, st) {
      AppLogger.e(_tag, 'createUser() ❌', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() => state = const CreateUserState();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final createUserProvider =
    StateNotifierProvider<CreateUserNotifier, CreateUserState>((ref) {
  return CreateUserNotifier(ref.watch(authRemoteDataSourceProvider));
});
