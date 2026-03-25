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
    required String guestSurname,
    required String guestName,
    required String purpose,
    required DateTime validFrom,
    required DateTime validUntil,
    String guestPatronymic = '',
    String guestCompany = '',
    String note = '',
    String guestEmail = '',
    String guestPassword = '',
  }) async {
    AppLogger.i(_tag, 'create → guest=$guestSurname $guestName purpose=$purpose');
    final body = <String, dynamic>{
      'guest_surname': guestSurname,
      'guest_name': guestName,
      'guest_patronymic': guestPatronymic,
      'guest_company': guestCompany,
      'purpose': purpose,
      'note': note,
      'valid_from': validFrom.toUtc().toIso8601String(),
      'valid_until': validUntil.toUtc().toIso8601String(),
    };
    if (guestEmail.isNotEmpty) body['guest_email'] = guestEmail;
    if (guestPassword.isNotEmpty) body['guest_password'] = guestPassword;
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.guestPassesCreate,
      data: body,
    );
    final data = resp.data;
    if (data == null) throw Exception('Сервер вернул пустой ответ');
    final model = GuestPassModel.fromJson(data);
    AppLogger.i(_tag, 'create ✅ id=${model.id}');
    return model;
  }

  Future<GuestPassModel> revoke(int id) async {
    AppLogger.i(_tag, 'revoke → id=$id');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.guestPassRevoke(id),
    );
    final data = resp.data;
    if (data == null) throw Exception('Сервер вернул пустой ответ');
    final model = GuestPassModel.fromJson(data);
    AppLogger.i(_tag, 'revoke ✅ status=${model.status}');
    return model;
  }

  Future<Map<String, dynamic>> validate(String token) async {
    AppLogger.i(_tag, 'validate →');
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiConstants.guestPassesValidate,
      data: {'token': token},
    );
    final data = resp.data;
    if (data == null) throw Exception('Сервер вернул пустой ответ');
    AppLogger.i(_tag, 'validate ✅');
    return data;
  }
}
