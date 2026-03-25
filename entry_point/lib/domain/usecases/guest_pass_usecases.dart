import '../entities/guest_pass.dart';
import '../repositories/guest_pass_repository.dart';

class ListGuestPassesUseCase {
  ListGuestPassesUseCase(this._repo);
  final GuestPassRepository _repo;

  Future<List<GuestPass>> call() => _repo.list();
}

class CreateGuestPassUseCase {
  CreateGuestPassUseCase(this._repo);
  final GuestPassRepository _repo;

  Future<GuestPass> call({
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
  }) =>
      _repo.create(
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
}

class RevokeGuestPassUseCase {
  RevokeGuestPassUseCase(this._repo);
  final GuestPassRepository _repo;

  Future<GuestPass> call(int id) => _repo.revoke(id);
}
