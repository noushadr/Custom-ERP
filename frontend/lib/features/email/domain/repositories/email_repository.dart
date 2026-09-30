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

  /// [mailbox] is `'inbox'` or `'sent'`. Scoped to the last [monthsBack]
  /// months (via IMAP SEARCH, not a blind recent-count fetch) and capped
  /// at [limit] messages.
  Future<List<InboxMessage>> listMessages({
    String mailbox = 'inbox',
    int monthsBack = 6,
    int limit = 200,
  });

  Future<EmailMessageDetail> getMessage(int uid, {String mailbox = 'inbox'});

  /// Gmail-style conversations grouped across Inbox + Sent by subject.
  /// Scoped to the last [monthsBack] months and capped at [limit]
  /// conversations.
  Future<List<EmailThread>> listThreads({
    int monthsBack = 6,
    int limit = 200,
  });

  /// Every message in one conversation, oldest first, with full bodies.
  Future<EmailThreadDetail> getThread(String threadId, {int monthsBack = 6});
}
