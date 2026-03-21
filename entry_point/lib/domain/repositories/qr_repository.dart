import '../entities/qr_token.dart';
import '../entities/user.dart';

abstract interface class QrRepository {
  Future<QrToken> generate();
  /// Returns (result: 'granted'|'denied', user: User?)
  Future<({String result, User? user, String? detail})> validate(String token);
}
