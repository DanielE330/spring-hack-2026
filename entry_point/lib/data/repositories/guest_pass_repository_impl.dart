import '../../domain/entities/guest_pass.dart';
import '../../domain/repositories/guest_pass_repository.dart';
import '../sources/guest_pass_remote_data_source.dart';

class GuestPassRepositoryImpl implements GuestPassRepository {
  GuestPassRepositoryImpl(this._remote);

  final GuestPassRemoteDataSource _remote;

  @override
  Future<List<GuestPass>> list() async {
    final models = await _remote.list();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<GuestPass> create({
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
    final model = await _remote.create(
      guestSurname: guestSurname,
      guestName: guestName,
      guestPatronymic: guestPatronymic,
      purpose: purpose,
      validFrom: validFrom,
      validUntil: validUntil,
      guestCompany: guestCompany,
      note: note,
      guestEmail: guestEmail,
      guestPassword: guestPassword,
    );
    return model.toEntity();
  }

  @override
  Future<GuestPass> revoke(int id) async {
    final model = await _remote.revoke(id);
    return model.toEntity();
  }

  @override
  Future<Map<String, dynamic>> validate(String token) async {
    return _remote.validate(token);
  }
}
