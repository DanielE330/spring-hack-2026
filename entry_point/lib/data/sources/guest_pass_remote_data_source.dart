import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/guest_pass_model.dart';

class GuestPassRemoteDataSource {
  static const _tag = 'GuestPassRemoteDS';

  GuestPassRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<GuestPassModel>> list() async {
    AppLogger.i(_tag, 'list →');
    final resp = await _dio.get<List<dynamic>>(ApiConstants.guestPasses);
    final items = (resp.data ?? [])
        .map((e) => GuestPassModel.fromJson(e as Map<String, dynamic>))
        .toList();
    AppLogger.i(_tag, 'list ✅ count=${items.length}');
    return items;
  }

  Future<GuestPassModel> create({
    required String guestName,
    required String purpose,
    required DateTime validFrom,
    required DateTime validUntil,
    String guestCompany = '',
    String note = '',
  }) async {
    AppLogger.i(_tag, 'create → guest=$guestName purpose=$purpose');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.guestPassesCreate,
      data: {
        'guest_name': guestName,
        'guest_company': guestCompany,
        'purpose': purpose,
        'note': note,
        'valid_from': validFrom.toUtc().toIso8601String(),
        'valid_until': validUntil.toUtc().toIso8601String(),
      },
    );
    final model = GuestPassModel.fromJson(resp.data!);
    AppLogger.i(_tag, 'create ✅ id=${model.id}');
    return model;
  }

  Future<GuestPassModel> revoke(int id) async {
    AppLogger.i(_tag, 'revoke → id=$id');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.guestPassRevoke(id),
    );
    final model = GuestPassModel.fromJson(resp.data!);
    AppLogger.i(_tag, 'revoke ✅ status=${model.status}');
    return model;
  }

  Future<Map<String, dynamic>> validate(String token) async {
    AppLogger.i(_tag, 'validate →');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.guestPassesValidate,
      data: {'token': token},
    );
    AppLogger.i(_tag, 'validate ✅');
    return resp.data!;
  }
}
