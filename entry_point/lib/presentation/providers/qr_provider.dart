import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/qr_repository_impl.dart';
import '../../data/sources/qr_remote_data_source.dart';
import '../../domain/entities/qr_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/qr_repository.dart';

// ─── DI ───────────────────────────────────────────────────────────────────────

final qrRemoteDataSourceProvider = Provider<QrRemoteDataSource>(
  (_) => QrRemoteDataSource(),
);

final qrRepositoryProvider = Provider<QrRepository>(
  (ref) => QrRepositoryImpl(ref.watch(qrRemoteDataSourceProvider)),
);

// ─── QR state ─────────────────────────────────────────────────────────────────

class QrState {
  const QrState({
    this.qrToken,
    this.secondsLeft = 0,
    this.isLoading = false,
    this.error,
  });

  final QrToken? qrToken;
  final int secondsLeft;
  final bool isLoading;
  final String? error;

  QrState copyWith({
    QrToken? qrToken,
    int? secondsLeft,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      QrState(
        qrToken: qrToken ?? this.qrToken,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class QrNotifier extends StateNotifier<QrState> {
  static const _tag = 'QrNotifier';

  QrNotifier(this._repo) : super(const QrState());

  final QrRepository _repo;
  Timer? _timer;
  bool _disposed = false;

  static const _ttlSeconds = 300;

  Future<void> generate({bool forceNew = false}) async {
    if (_disposed) return;
    AppLogger.i(_tag, 'generate(forceNew=$forceNew)');
    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final qr = await _repo.generate(forceNew: forceNew);
      if (_disposed || !mounted) return;
      // Всегда сбрасываем таймер на 300 сек — QR всегда новый
      state = QrState(qrToken: qr, secondsLeft: _ttlSeconds, isLoading: false);
      _startCountdown();
      AppLogger.i(_tag, 'generate() ✅ secondsLeft=$_ttlSeconds');
    } catch (e, st) {
      AppLogger.e(_tag, 'generate() ❌', error: e, stackTrace: st);
      if (_disposed || !mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        _timer = null;
        return;
      }
      try {
        if (state.secondsLeft <= 1) {
          timer.cancel();
          _timer = null;
          AppLogger.i(_tag, 'QR expired — auto-regenerating');
          generate();
        } else {
          state = state.copyWith(secondsLeft: state.secondsLeft - 1);
        }
      } catch (e) {
        timer.cancel();
        _timer = null;
        AppLogger.w(_tag, 'Timer cancelled — widget disposed');
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

final qrProvider = StateNotifierProvider.autoDispose<QrNotifier, QrState>((ref) {
  return QrNotifier(ref.watch(qrRepositoryProvider));
});

// ─── Validate state ───────────────────────────────────────────────────────────

class ValidateResult {
  const ValidateResult({
    required this.isGranted,
    this.user,
    this.detail,
  });

  final bool isGranted;
  final User? user;
  final String? detail;
}

class ScannerState {
  const ScannerState({
    this.result,
    this.isLoading = false,
    this.error,
  });

  final ValidateResult? result;
  final bool isLoading;
  final String? error;

  ScannerState copyWith({
    ValidateResult? result,
    bool? isLoading,
    String? error,
    bool clearAll = false,
  }) {
    if (clearAll) return const ScannerState();
    return ScannerState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  static const _tag = 'ScannerNotifier';

  ScannerNotifier(this._repo) : super(const ScannerState());

  final QrRepository _repo;

  Future<void> validate(String token) async {
    AppLogger.i(_tag, 'validate()');
    state = state.copyWith(isLoading: true);
    try {
      final r = await _repo.validate(token);
      state = state.copyWith(
        isLoading: false,
        result: ValidateResult(
          isGranted: r.result == 'granted',
          user: r.user,
          detail: r.detail,
        ),
      );
    } catch (e, st) {
      AppLogger.e(_tag, 'validate() ❌', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        result: ValidateResult(isGranted: false, detail: e.toString()),
      );
    }
  }

  void reset() => state = state.copyWith(clearAll: true);
}

final scannerProvider =
    StateNotifierProvider.autoDispose<ScannerNotifier, ScannerState>((ref) {
  return ScannerNotifier(ref.watch(qrRepositoryProvider));
});
