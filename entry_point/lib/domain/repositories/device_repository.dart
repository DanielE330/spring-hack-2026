import '../entities/device.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> getMyDevices();
  Future<void> deleteDevice(int id);
}
