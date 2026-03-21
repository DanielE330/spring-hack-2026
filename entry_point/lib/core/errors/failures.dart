import 'package:equatable/equatable.dart';

/// Base domain failure.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет соединения с сервером.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode, this.errors});

  final int? statusCode;
  final Map<String, List<String>>? errors;
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Необходима авторизация.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.errors});

  final Map<String, List<String>>? errors;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Неизвестная ошибка.']);
}
