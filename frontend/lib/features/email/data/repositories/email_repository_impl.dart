import 'package:dio/dio.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/inbox_message.dart';
import '../../domain/exceptions/email_exception.dart';
import '../../domain/repositories/email_repository.dart';
import '../datasources/email_remote_data_source.dart';

class EmailRepositoryImpl implements EmailRepository {
  const EmailRepositoryImpl(this._remoteDataSource);

  final EmailRemoteDataSource _remoteDataSource;

  Map<String, dynamic> _accountBody({
    required String emailAddress,
    required String password,
    required String smtpHost,
    int? smtpPort,
    required String imapHost,
    int? imapPort,
    bool? smtpSecure,
  }) => {
    'emailAddress': emailAddress,
    'password': password,
    'smtpHost': smtpHost,
    'smtpPort': ?smtpPort,
    'imapHost': imapHost,
    'imapPort': ?imapPort,
    'smtpSecure': ?smtpSecure,
  };

  @override
  Future<EmailAccount?> getMyAccount() =>
      _guard(() => _remoteDataSource.getMyAccount());

  @override
  Future<EmailAccount> setupMyAccount({
    required String emailAddress,
    required String password,
    required String smtpHost,
    int? smtpPort,
    required String imapHost,
    int? imapPort,
    bool? smtpSecure,
  }) => _guard(
    () => _remoteDataSource.setupMyAccount(
      _accountBody(
        emailAddress: emailAddress,
        password: password,
        smtpHost: smtpHost,
        smtpPort: smtpPort,
        imapHost: imapHost,
        imapPort: imapPort,
        smtpSecure: smtpSecure,
      ),
    ),
  );

  @override
  Future<void> removeMyAccount() =>
      _guard(() => _remoteDataSource.removeMyAccount());

  @override
  Future<EmailAccount?> getAccountForEmployee(String employeeId) =>
      _guard(() => _remoteDataSource.getAccountForEmployee(employeeId));

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
  }) => _guard(
    () => _remoteDataSource.setupForEmployee(
      employeeId,
      _accountBody(
        emailAddress: emailAddress,
        password: password,
        smtpHost: smtpHost,
        smtpPort: smtpPort,
        imapHost: imapHost,
        imapPort: imapPort,
        smtpSecure: smtpSecure,
      ),
    ),
  );

  @override
  Future<void> removeForEmployee(String employeeId) =>
      _guard(() => _remoteDataSource.removeForEmployee(employeeId));

  @override
  Future<void> sendMail({
    required String to,
    required String subject,
    required String body,
  }) => _guard(
    () => _remoteDataSource.sendMail(to: to, subject: subject, body: body),
  );

  @override
  Future<List<InboxMessage>> listInbox({int limit = 25}) =>
      _guard(() => _remoteDataSource.listInbox(limit: limit));

  @override
  Future<EmailMessageDetail> getMessage(int uid) =>
      _guard(() => _remoteDataSource.getMessage(uid));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw EmailException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
