import 'package:zera_erp/features/email/domain/entities/email_account.dart';
import 'package:zera_erp/features/email/domain/entities/inbox_message.dart';
import 'package:zera_erp/features/email/domain/repositories/email_repository.dart';

EmailAccount buildTestEmailAccount({
  String id = 'account-1',
  String employeeId = 'employee-1',
  String emailAddress = 'employee@zeracreative.com',
  String smtpHost = 'mail.zeracreative.com',
  int smtpPort = 587,
  String imapHost = 'mail.zeracreative.com',
  int imapPort = 993,
  bool smtpSecure = true,
}) {
  return EmailAccount(
    id: id,
    employeeId: employeeId,
    emailAddress: emailAddress,
    smtpHost: smtpHost,
    smtpPort: smtpPort,
    imapHost: imapHost,
    imapPort: imapPort,
    smtpSecure: smtpSecure,
  );
}

class FakeEmailRepository implements EmailRepository {
  FakeEmailRepository({
    this.myAccount,
    this.inbox = const [],
    this.actionError,
  });

  EmailAccount? myAccount;
  final List<InboxMessage> inbox;
  final Object? actionError;

  @override
  Future<EmailAccount?> getMyAccount() async => myAccount;

  @override
  Future<EmailAccount> setupMyAccount({
    required String emailAddress,
    required String password,
    required String smtpHost,
    int? smtpPort,
    required String imapHost,
    int? imapPort,
    bool? smtpSecure,
  }) async {
    if (actionError != null) throw actionError!;
    final account = buildTestEmailAccount(emailAddress: emailAddress);
    myAccount = account;
    return account;
  }

  @override
  Future<void> removeMyAccount() async {
    if (actionError != null) throw actionError!;
    myAccount = null;
  }

  @override
  Future<EmailAccount?> getAccountForEmployee(String employeeId) async => null;

  @override
  Future<EmailAccount> setupForEmployee(
    String employeeId, {
    required String emailAddress,
    required String password,
    required String smtpHost,
    int? smtpPort,
    required String imapHost,
    int? imapPort,
    bool? smtpSecure,
  }) async {
    if (actionError != null) throw actionError!;
    return buildTestEmailAccount(
      employeeId: employeeId,
      emailAddress: emailAddress,
    );
  }

  @override
  Future<void> removeForEmployee(String employeeId) async {
    if (actionError != null) throw actionError!;
  }

  @override
  Future<void> sendMail({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (actionError != null) throw actionError!;
  }

  @override
  Future<List<InboxMessage>> listInbox({int limit = 25}) async => inbox;

  @override
  Future<EmailMessageDetail> getMessage(int uid) async {
    return EmailMessageDetail(
      subject: 'Subject',
      from: 'sender@example.com',
      date: DateTime(2026, 9, 9),
      text: 'Body',
    );
  }
}
