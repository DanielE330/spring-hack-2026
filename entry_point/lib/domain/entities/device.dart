import 'package:equatable/equatable.dart';

class Device extends Equatable {
  const Device({
    required this.id,
    required this.deviceName,
    this.ipAddress,
    this.lastUsed,
    this.isCurrent = false,
  });

  final int id;
  final String deviceName;
  final String? ipAddress;
  final DateTime? lastUsed;
  final bool isCurrent;

  @override
  List<Object?> get props => [id, deviceName, ipAddress, lastUsed, isCurrent];
}
