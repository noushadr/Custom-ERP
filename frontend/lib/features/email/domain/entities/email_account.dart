/// A viewer's own real cPanel mailbox config, as stored in the ERP — never
/// carries the password past the request that set it.
class EmailAccount {
  const EmailAccount({
    required this.id,
    required this.employeeId,
    required this.emailAddress,
    required this.smtpHost,
    required this.smtpPort,
    required this.imapHost,
    required this.imapPort,
    required this.smtpSecure,
  });

  final String id;
  final String employeeId;
  final String emailAddress;
  final String smtpHost;
  final int smtpPort;
  final String imapHost;
  final int imapPort;
  final bool smtpSecure;
}
