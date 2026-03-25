import '../entities/guest_pass.dart';

abstract class GuestPassRepository {
  /// Список всех гостевых пропусков (только admin).
  Future<List<GuestPass>> list();

  /// Создать гостевой пропуск.
  Future<GuestPass> create({
    required String guestSurname,
    required String guestName,
    required String purpose,
    required DateTime validFrom,
    required DateTime validUntil,
    String guestPatronymic,
    String guestCompany,
    String note,
    String guestEmail,
    String guestPassword,
  });

  /// Отменить гостевой пропуск.
  Future<GuestPass> revoke(int id);

  /// Валидировать токен (при сканировании).
  Future<Map<String, dynamic>> validate(String token);
}
