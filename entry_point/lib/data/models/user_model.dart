import '../../domain/entities/user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.patronymic,
    this.avatarUrl,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name:       (json['name']       as String?) ?? '',
        surname:    (json['surname']    as String?) ?? '',
        patronymic: json['patronymic']  as String?,
        email:      (json['email']      as String?) ?? '',
        avatarUrl:  json['avatar_url']  as String?,
        isAdmin:    (json['is_admin']   as bool?)   ?? false,
      );

  final int id;
  final String name;
  final String surname;
  final String? patronymic;
  final String email;
  final String? avatarUrl;
  final bool isAdmin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surname': surname,
        if (patronymic != null) 'patronymic': patronymic,
        'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'is_admin': isAdmin,
      };

  User toEntity() => User(
        id: id,
        name: name,
        surname: surname,
        patronymic: patronymic,
        email: email,
        avatarUrl: avatarUrl,
        isAdmin: isAdmin,
      );
}
