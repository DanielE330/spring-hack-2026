import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../data/sources/device_remote_data_source.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';

// ─── DI ───────────────────────────────────────────────────────────────────────

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>(
  (_) => DeviceRemoteDataSource(),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(ref.watch(deviceRemoteDataSourceProvider)),
);

// ─── Devices state ─────────────────────────────────────────────────────────────

class DevicesState {
  const DevicesState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Device> devices;
  final bool isLoading;
  final String? error;

  DevicesState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      DevicesState(
        devices: devices ?? this.devices,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class DevicesNotifier extends StateNotifier<DevicesState> {
  static const _tag = 'DevicesNotifier';

  DevicesNotifier(this._repo) : super(const DevicesState());

  final DeviceRepository _repo;

  Future<void> load() async {
    AppLogger.i(_tag, 'load()');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final devices = await _repo.getMyDevices();
      state = state.copyWith(devices: devices, isLoading: false);
      AppLogger.i(_tag, 'load() ✅ count=${devices.length}');
    } catch (e, st) {
      AppLogger.e(_tag, 'load() ❌', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(int id) async {
    AppLogger.w(_tag, 'delete() id=$id');
    try {
      await _repo.deleteDevice(id);
      state = state.copyWith(
        devices: state.devices.where((d) => d.id != id).toList(),
      );
      AppLogger.i(_tag, 'delete() ✅ id=$id');
    } catch (e, st) {
      AppLogger.e(_tag, 'delete() ❌', error: e, stackTrace: st);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> adminDelete(int id) async {
    AppLogger.w(_tag, 'adminDelete() id=$id');
    try {
      await _repo.adminDeleteDevice(id);
      state = state.copyWith(
        devices: state.devices.where((d) => d.id != id).toList(),
      );
      AppLogger.i(_tag, 'adminDelete() ✅ id=$id');
    } catch (e, st) {
      AppLogger.e(_tag, 'adminDelete() ❌', error: e, stackTrace: st);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<int>?> downloadReport() async {
    AppLogger.i(_tag, 'downloadReport()');
    try {
      final bytes = await _repo.downloadAttendanceReport();
      AppLogger.i(_tag, 'downloadReport() ✅ bytes=${bytes.length}');
      return bytes;
    } catch (e, st) {
      AppLogger.e(_tag, 'downloadReport() ❌', error: e, stackTrace: st);
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final devicesProvider =
    StateNotifierProvider.autoDispose<DevicesNotifier, DevicesState>((ref) {
  return DevicesNotifier(ref.watch(deviceRepositoryProvider));
});
