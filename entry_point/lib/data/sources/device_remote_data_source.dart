import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/device_model.dart';

class DeviceRemoteDataSource {
  static const _tag = 'DeviceRemoteDS';

  DeviceRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<DeviceModel>> getMyDevices() async {
    AppLogger.i(_tag, 'getMyDevices →');
    final resp = await _dio.get<List<dynamic>>(ApiConstants.myDevices);
    final list = (resp.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(DeviceModel.fromJson)
        .toList();
    AppLogger.i(_tag, 'getMyDevices ✅ count=${list.length}');
    return list;
  }

  Future<void> deleteDevice(int id) async {
    AppLogger.w(_tag, 'deleteDevice → id=$id');
    await _dio.delete<dynamic>(ApiConstants.deviceById(id.toString()));
    AppLogger.i(_tag, 'deleteDevice ✅ id=$id');
  }
}
