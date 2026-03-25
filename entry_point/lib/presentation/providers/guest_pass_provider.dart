import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/error_helpers.dart';
import '../../data/repositories/guest_pass_repository_impl.dart';
import '../../data/sources/guest_pass_remote_data_source.dart';
import '../../domain/entities/guest_pass.dart';
import '../../domain/repositories/guest_pass_repository.dart';
import '../../domain/usecases/guest_pass_usecases.dart';

// ─── DI ───────────────────────────────────────────────────────────────────────

final guestPassRemoteDataSourceProvider = Provider<GuestPassRemoteDataSource>(
  (_) => GuestPassRemoteDataSource(),
);

final guestPassRepositoryProvider = Provider<GuestPassRepository>(
  (ref) => GuestPassRepositoryImpl(ref.watch(guestPassRemoteDataSourceProvider)),
);

final listGuestPassesUseCaseProvider = Provider(
  (ref) => ListGuestPassesUseCase(ref.watch(guestPassRepositoryProvider)),
);

final createGuestPassUseCaseProvider = Provider(
  (ref) => CreateGuestPassUseCase(ref.watch(guestPassRepositoryProvider)),
);

final revokeGuestPassUseCaseProvider = Provider(
  (ref) => RevokeGuestPassUseCase(ref.watch(guestPassRepositoryProvider)),
);

// ─── State ────────────────────────────────────────────────────────────────────

class GuestPassState {
  const GuestPassState({
    this.passes = const [],
    this.isLoading = false,
    this.error,
  });

  final List<GuestPass> passes;
  final bool isLoading;
  final String? error;

  GuestPassState copyWith({
    List<GuestPass>? passes,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      GuestPassState(
        passes: passes ?? this.passes,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GuestPassNotifier extends StateNotifier<GuestPassState> {
  static const _tag = 'GuestPassNotifier';

  GuestPassNotifier(this._list, this._create, this._revoke)
      : super(const GuestPassState());

  final ListGuestPassesUseCase _list;
  final CreateGuestPassUseCase _create;
  final RevokeGuestPassUseCase _revoke;

  Future<void> loadPasses() async {
    AppLogger.i(_tag, 'loadPasses()');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final passes = await _list();
      state = state.copyWith(passes: passes, isLoading: false);
      AppLogger.i(_tag, 'loadPasses() ✅ count=${passes.length}');
    } catch (e, st) {
      AppLogger.e(_tag, 'loadPasses() ❌', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> createPass({
    required String guestSurname,
    required String guestName,
    required String purpose,
    required DateTime validFrom,
    required DateTime validUntil,
    String guestPatronymic = '',
    String guestCompany = '',
    String note = '',
    String guestEmail = '',
    String guestPassword = '',
  }) async {
    AppLogger.i(_tag, 'createPass() guest=$guestSurname $guestName');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pass = await _create(
        guestSurname: guestSurname,
        guestName: guestName,
        guestPatronymic: guestPatronymic,
        purpose: purpose,
        validFrom: validFrom,
        validUntil: validUntil,
        guestCompany: guestCompany,
        note: note,
        guestEmail: guestEmail,
        guestPassword: guestPassword,
      );
      state = state.copyWith(
        passes: [pass, ...state.passes],
        isLoading: false,
      );
      AppLogger.i(_tag, 'createPass() ✅ id=${pass.id}');
      return true;
    } catch (e, st) {
      AppLogger.e(_tag, 'createPass() ❌', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> revokePass(int id) async {
    AppLogger.i(_tag, 'revokePass() id=$id');
    try {
      final updated = await _revoke(id);
      state = state.copyWith(
        passes: state.passes.map((p) => p.id == id ? updated : p).toList(),
      );
      AppLogger.i(_tag, 'revokePass() ✅');
      return true;
    } catch (e, st) {
      AppLogger.e(_tag, 'revokePass() ❌', error: e, stackTrace: st);
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }
}

final guestPassProvider =
    StateNotifierProvider<GuestPassNotifier, GuestPassState>((ref) {
  return GuestPassNotifier(
    ref.watch(listGuestPassesUseCaseProvider),
    ref.watch(createGuestPassUseCaseProvider),
    ref.watch(revokeGuestPassUseCaseProvider),
  );
});
