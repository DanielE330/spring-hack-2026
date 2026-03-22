import 'dart:typed_data';
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

  /// DELETE /admin/devices/{id}/ (admin only)
  Future<void> adminDeleteDevice(int id) async {
    AppLogger.w(_tag, 'adminDeleteDevice → id=$id');
    await _dio.delete<dynamic>(ApiConstants.adminDeviceById(id.toString()));
    AppLogger.i(_tag, 'adminDeleteDevice ✅ id=$id');
  }

  /// GET /reports/attendance/ — скачивание Excel-отчёта
  Future<List<int>> downloadAttendanceReport() async {
    AppLogger.i(_tag, 'downloadAttendanceReport →');
    final resp = await _dio.get<dynamic>(
      ApiConstants.reportsAttendance,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': '*/*'},
      ),
    );
    AppLogger.i(_tag, 'downloadAttendanceReport resp status=${resp.statusCode} '
        'dataType=${resp.data?.runtimeType}');
    final raw = resp.data;
    late final List<int> data;
    if (raw is Uint8List) {
      data = raw;
    } else if (raw is List) {
      data = List<int>.from(raw);
    } else {
      throw Exception('Неожиданный тип ответа: ${raw.runtimeType}');
    }
    if (data.isEmpty) {
      throw Exception('Сервер вернул пустой ответ');
    }
    AppLogger.i(_tag, 'downloadAttendanceReport ✅ bytes=${data.length}');
    return data;
  }
}
