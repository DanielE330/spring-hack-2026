import '../../domain/entities/guest_pass.dart';

class GuestPassModel {
  const GuestPassModel({
    required this.id,
    required this.guestSurname,
    required this.guestName,
    required this.guestPatronymic,
    required this.guestFullName,
    required this.guestCompany,
    required this.purpose,
    required this.note,
    required this.token,
    required this.status,
    required this.createdBy,
    required this.createdByEmail,
    required this.createdAt,
    required this.validFrom,
    required this.validUntil,
    this.usedAt,
    this.revokedAt,
    this.isValid = false,
    this.isExpired = false,
    this.hasAccount = false,
    this.userEmail,
  });

  factory GuestPassModel.fromJson(Map<String, dynamic> json) {
    return GuestPassModel(
      id:             json['id'] as int,
      guestSurname:   json['guest_surname'] as String? ?? '',
      guestName:      json['guest_name'] as String? ?? '',
      guestPatronymic: json['guest_patronymic'] as String? ?? '',
      guestFullName:  json['guest_full_name'] as String? ?? '',
      guestCompany:   json['guest_company'] as String? ?? '',
      purpose:        json['purpose'] as String? ?? 'other',
      note:           json['note'] as String? ?? '',
      token:          json['token'] as String? ?? '',
      status:         json['status'] as String? ?? 'active',
      createdBy:      json['created_by'] as int?,
      createdByEmail: json['created_by_email'] as String?,
      createdAt:      DateTime.parse(json['created_at'] as String),
      validFrom:      DateTime.parse(json['valid_from'] as String),
      validUntil:     DateTime.parse(json['valid_until'] as String),
      usedAt:         json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
      revokedAt:      json['revoked_at'] != null ? DateTime.parse(json['revoked_at'] as String) : null,
      isValid:        json['is_valid'] as bool? ?? false,
      isExpired:      json['is_expired'] as bool? ?? false,
      hasAccount:     json['has_account'] as bool? ?? false,
      userEmail:      json['user_email'] as String?,
    );
  }

  final int id;
  final String guestSurname;
  final String guestName;
  final String guestPatronymic;
  final String guestFullName;
  final String guestCompany;
  final String purpose;
  final String note;
  final String token;
  final String status;
  final int? createdBy;
  final String? createdByEmail;
  final DateTime createdAt;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime? usedAt;
  final DateTime? revokedAt;
  final bool isValid;
  final bool isExpired;
  final bool hasAccount;
  final String? userEmail;

  GuestPass toEntity() => GuestPass(
    id: id,
    guestSurname: guestSurname,
    guestName: guestName,
    guestPatronymic: guestPatronymic,
    guestFullName: guestFullName,
    guestCompany: guestCompany,
    purpose: purpose,
    note: note,
    token: token,
    status: status,
    createdBy: createdBy,
    createdByEmail: createdByEmail,
    createdAt: createdAt,
    validFrom: validFrom,
    validUntil: validUntil,
    usedAt: usedAt,
    revokedAt: revokedAt,
    isValid: isValid,
    isExpired: isExpired,
    hasAccount: hasAccount,
    userEmail: userEmail,
  );
}
