import '../../core/utils/app_logger.dart';
import '../../data/models/user_model.dart';
import '../../data/sources/qr_remote_data_source.dart';
import '../../domain/entities/qr_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/qr_repository.dart';

class QrRepositoryImpl implements QrRepository {
  static const _tag = 'QrRepo';

  QrRepositoryImpl(this._remote);

  final QrRemoteDataSource _remote;

  @override
  Future<QrToken> generate({bool forceNew = false}) async {
    AppLogger.i(_tag, 'generate(forceNew=$forceNew)');
    try {
      final m = await _remote.generate(forceNew: forceNew);
      AppLogger.i(_tag, 'generate() ✅ secondsLeft=${m.secondsLeft}');
      return m.toEntity();
    } catch (e, st) {
      AppLogger.e(_tag, 'generate() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<({
    String result,
    User? user,
    String? detail,
    String? attendanceEvent,
    DateTime? enteredAt,
    DateTime? exitedAt,
    int? workedSeconds,
  })> validate(String token) async {
    AppLogger.i(_tag, 'validate()');
    try {
      final data = await _remote.validate(token);
      final result = (data['result'] as String?) ?? 'denied';
      User? user;
      if (data['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>).toEntity();
      }
      final detail = data['detail'] as String?;
      final attendanceEvent = data['attendance_event'] as String?;
      final enteredAt = data['entered_at'] != null
          ? DateTime.tryParse(data['entered_at'] as String)
          : null;
      final exitedAt = data['exited_at'] != null
          ? DateTime.tryParse(data['exited_at'] as String)
          : null;
      final workedSeconds = data['worked_seconds'] as int?;
      AppLogger.i(_tag, 'validate() ✅ result=$result event=$attendanceEvent');
      return (
        result: result,
        user: user,
        detail: detail,
        attendanceEvent: attendanceEvent,
        enteredAt: enteredAt,
        exitedAt: exitedAt,
        workedSeconds: workedSeconds,
      );
    } catch (e, st) {
      AppLogger.e(_tag, 'validate() ❌', error: e, stackTrace: st);
      rethrow;
    }
  }
}
