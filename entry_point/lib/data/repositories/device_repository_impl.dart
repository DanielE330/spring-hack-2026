import '../../core/utils/app_logger.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../sources/device_remote_data_source.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  static const _tag = 'DeviceRepo';

  DeviceRepositoryImpl(this._remote);

  final DeviceRemoteDataSource _remote;

  @override
  Future<List<Device>> getMyDevices() async {
    AppLogger.i(_tag, 'getMyDevices()');
    try {
      final models = await _remote.getMyDevices();
      AppLogger.i(_tag, 'getMyDevices() ✅ count=${models.length}');
      return models.map((m) => m.toEntity()).toList();
    } catch (e, st) {
      AppLogger.e(_tag, 'getMyDevices() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> deleteDevice(int id) async {
    AppLogger.w(_tag, 'deleteDevice() id=$id');
    try {
      await _remote.deleteDevice(id);
      AppLogger.i(_tag, 'deleteDevice() ✅');
    } catch (e, st) {
      AppLogger.e(_tag, 'deleteDevice() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> adminDeleteDevice(int id) async {
    AppLogger.w(_tag, 'adminDeleteDevice() id=$id');
    try {
      await _remote.adminDeleteDevice(id);
      AppLogger.i(_tag, 'adminDeleteDevice() ✅');
    } catch (e, st) {
      AppLogger.e(_tag, 'adminDeleteDevice() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadAttendanceReport() async {
    AppLogger.i(_tag, 'downloadAttendanceReport()');
    try {
      final bytes = await _remote.downloadAttendanceReport();
      AppLogger.i(_tag, 'downloadAttendanceReport() ✅ bytes=${bytes.length}');
      return bytes;
    } catch (e, st) {
      AppLogger.e(_tag, 'downloadAttendanceReport() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }
}
