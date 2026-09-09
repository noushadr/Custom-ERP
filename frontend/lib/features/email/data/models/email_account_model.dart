import '../../domain/entities/email_account.dart';

class EmailAccountModel extends EmailAccount {
  const EmailAccountModel({
    required super.id,
    required super.employeeId,
    required super.emailAddress,
    required super.smtpHost,
    required super.smtpPort,
    required super.imapHost,
    required super.imapPort,
    required super.smtpSecure,
  });

  factory EmailAccountModel.fromJson(Map<String, dynamic> json) =>
      EmailAccountModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        emailAddress: json['emailAddress'] as String,
        smtpHost: json['smtpHost'] as String,
        smtpPort: json['smtpPort'] as int,
        imapHost: json['imapHost'] as String,
        imapPort: json['imapPort'] as int,
        smtpSecure: json['smtpSecure'] as bool,
      );
}
