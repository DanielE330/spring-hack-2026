import '../../domain/entities/qr_token.dart';

class QrTokenModel {
  const QrTokenModel({
    required this.token,
    required this.secondsLeft,
  });

  factory QrTokenModel.fromJson(Map<String, dynamic> json) => QrTokenModel(
        token:      (json['token']        as String?) ?? '',
        secondsLeft:(json['seconds_left'] as int?)    ?? 60,
      );

  final String token;
  final int secondsLeft;

  QrToken toEntity() => QrToken(token: token, secondsLeft: secondsLeft);
}
