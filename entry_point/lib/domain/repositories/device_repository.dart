import '../entities/device.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> getMyDevices();
  Future<void> deleteDevice(int id);

  /// DELETE /admin/devices/{id}/ (admin only)
  Future<void> adminDeleteDevice(int id);

  /// GET /reports/attendance/ — download Excel report bytes
  Future<List<int>> downloadAttendanceReport();
}
