import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.patronymic,
    this.avatarUrl,
    this.isAdmin = false,
  });

  final int id;
  final String name;
  final String surname;
  final String? patronymic;
  final String email;
  final String? avatarUrl;
  final bool isAdmin;

  /// Full name: "Фамилия Имя [Отчество]"
  String get fullName {
    final parts = [surname, name, patronymic];
    return parts.whereType<String>().join(' ');
  }

  /// First letter of name for avatars.
  String get initials {
    final s = surname.isNotEmpty ? surname[0].toUpperCase() : '';
    final n = name.isNotEmpty ? name[0].toUpperCase() : '';
    return '$s$n';
  }

  User copyWith({
    int? id,
    String? name,
    String? surname,
    String? patronymic,
    String? email,
    String? avatarUrl,
    bool? isAdmin,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        surname: surname ?? this.surname,
        patronymic: patronymic ?? this.patronymic,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isAdmin: isAdmin ?? this.isAdmin,
      );

  @override
  List<Object?> get props => [id, name, surname, patronymic, email, avatarUrl, isAdmin];
}
