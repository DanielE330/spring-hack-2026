import '../../domain/entities/device.dart';

class DeviceModel {
  const DeviceModel({
    required this.id,
    required this.deviceName,
    this.ipAddress,
    this.lastUsed,
    this.isCurrent = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        id:         json['id']          as int,
        deviceName: (json['device_name'] as String?) ?? 'Unknown',
        ipAddress:  json['ip_address']  as String?,
        lastUsed:   json['last_used'] != null
            ? DateTime.tryParse(json['last_used'] as String)
            : null,
        isCurrent:  (json['is_current'] as bool?) ?? false,
      );

  final int id;
  final String deviceName;
  final String? ipAddress;
  final DateTime? lastUsed;
  final bool isCurrent;

  Device toEntity() => Device(
        id: id,
        deviceName: deviceName,
        ipAddress: ipAddress,
        lastUsed: lastUsed,
        isCurrent: isCurrent,
      );
}
