import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/qr_token_model.dart';

class QrRemoteDataSource {
  static const _tag = 'QrRemoteDS';

  QrRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<QrTokenModel> generate({bool forceNew = false}) async {
    AppLogger.i(_tag, 'generate → forceNew=$forceNew');
    // Всегда запрашиваем абсолютно новый QR-код
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.qrGenerate,
      data: {'force_new': true},
      queryParameters: {'force_new': '1'},
    );
    final model = QrTokenModel.fromJson(resp.data!);
    AppLogger.i(_tag, 'generate ✅ secondsLeft=${model.secondsLeft}');
    return model;
  }

  Future<Map<String, dynamic>> validate(String token) async {
    AppLogger.i(_tag, 'validate →');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.qrValidate,
      data: {'token': token},
    );
    AppLogger.i(_tag, 'validate ✅');
    return resp.data!;
  }
}
