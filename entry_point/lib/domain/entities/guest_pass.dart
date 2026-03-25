import 'package:equatable/equatable.dart';

class GuestPass extends Equatable {
  const GuestPass({
    required this.id,
    required this.guestSurname,
    required this.guestName,
    required this.purpose,
    required this.status,
    required this.token,
    required this.createdAt,
    required this.validFrom,
    required this.validUntil,
    this.guestPatronymic = '',
    this.guestFullName = '',
    this.guestCompany = '',
    this.note = '',
    this.createdBy,
    this.createdByEmail,
    this.usedAt,
    this.revokedAt,
    this.isValid = false,
    this.isExpired = false,
    this.hasAccount = false,
    this.userEmail,
  });

  final int id;
  final String guestSurname;
  final String guestName;
  final String guestPatronymic;
  final String guestFullName;
  final String guestCompany;
  final String purpose;
  final String note;
  final String token;
  final String status;   // active, used, expired, revoked

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

  String get purposeLabel {
    switch (purpose) {
      case 'meeting':       return 'Встреча';
      case 'contractor':    return 'Подрядчик';
      case 'delivery':      return 'Доставка/Курьер';
      case 'temp_employee': return 'Временный сотрудник';
      default:              return 'Другое';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':  return 'Активен';
      case 'used':    return 'Использован';
      case 'expired': return 'Истёк';
      case 'revoked': return 'Отменён';
      default:        return status;
    }
  }

  @override
  List<Object?> get props => [
    id, guestSurname, guestName, guestPatronymic, guestFullName,
    guestCompany, purpose, note, token, status,
    createdBy, createdByEmail, createdAt, validFrom, validUntil,
    usedAt, revokedAt, isValid, isExpired, hasAccount, userEmail,
  ];
}
