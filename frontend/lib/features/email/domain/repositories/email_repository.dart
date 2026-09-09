import '../entities/email_account.dart';
import '../entities/inbox_message.dart';

abstract interface class EmailRepository {
  /// The viewer's own mailbox config, or `null` if not set up yet.
  Future<EmailAccount?> getMyAccount();

  /// The viewer enters their own real cPanel mailbox's credentials.
  Future<EmailAccount> setupMyAccount({
    required String emailAddress,
    required String password,
    required String smtpHost,
    int? smtpPort,
    required String imapHost,
    int? imapPort,
    bool? smtpSecure,
  });

  Future<void> removeMyAccount();

  /// Requires `email.manage`.
  Future<EmailAccount?> getAccountForEmployee(String employeeId);

  /// Requires `email.manage`.
  Future<EmailAccount> setupForEmployee(
    String employeeId, {
    required String emailAddress,
    required String password,
    required String smtpHost,
    int? smtpPort,
    required String imapHost,
    int? imapPort,
    bool? smtpSecure,
  });

  /// Requires `email.manage`.
  Future<void> removeForEmployee(String employeeId);

  Future<void> sendMail({
    required String to,
    required String subject,
    required String body,
  });

  Future<List<InboxMessage>> listInbox({int limit = 25});

  Future<EmailMessageDetail> getMessage(int uid);
}
