import '../../domain/entities/guest_pass.dart';

class GuestPassModel {
  const GuestPassModel({
    required this.id,
    required this.guestName,
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
  });

  factory GuestPassModel.fromJson(Map<String, dynamic> json) {
    return GuestPassModel(
      id:             json['id'] as int,
      guestName:      json['guest_name'] as String? ?? '',
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
    );
  }

  final int id;
  final String guestName;
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

  GuestPass toEntity() => GuestPass(
    id: id,
    guestName: guestName,
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
  );
}
