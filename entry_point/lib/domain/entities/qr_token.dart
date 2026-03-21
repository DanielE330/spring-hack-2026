import 'package:equatable/equatable.dart';

class QrToken extends Equatable {
  const QrToken({
    required this.token,
    required this.secondsLeft,
  });

  final String token;
  final int secondsLeft;

  @override
  List<Object?> get props => [token, secondsLeft];
}
