import 'package:dio/dio.dart';
import '../models/email_account_model.dart';
import '../models/inbox_message_model.dart';

class EmailRemoteDataSource {
  const EmailRemoteDataSource(this._dio);

  final Dio _dio;

  Future<EmailAccountModel?> getMyAccount() async {
    final response = await _dio.get<Map<String, dynamic>?>('/email/account/me');
    final data = response.data;
    return data == null ? null : EmailAccountModel.fromJson(data);
  }

  Future<EmailAccountModel> setupMyAccount(Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/email/account/me',
      data: body,
    );
    return EmailAccountModel.fromJson(response.data!);
  }

  Future<void> removeMyAccount() => _dio.delete('/email/account/me');

  Future<EmailAccountModel?> getAccountForEmployee(String employeeId) async {
    final response = await _dio.get<Map<String, dynamic>?>(
      '/email/account/$employeeId',
    );
    final data = response.data;
    return data == null ? null : EmailAccountModel.fromJson(data);
  }

  Future<EmailAccountModel> setupForEmployee(
    String employeeId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/email/account/$employeeId',
      data: body,
    );
    return EmailAccountModel.fromJson(response.data!);
  }

  Future<void> removeForEmployee(String employeeId) =>
      _dio.delete('/email/account/$employeeId');

  Future<void> sendMail({
    required String to,
    required String subject,
    required String body,
  }) => _dio.post(
    '/email/send',
    data: {'to': to, 'subject': subject, 'body': body},
  );

  Future<List<InboxMessageModel>> listMessages({
    String mailbox = 'inbox',
    int monthsBack = 6,
    int limit = 200,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/email/inbox',
      queryParameters: {
        'mailbox': mailbox,
        'months': monthsBack,
        'limit': limit,
      },
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(InboxMessageModel.fromJson)
        .toList();
  }

  Future<EmailMessageDetailModel> getMessage(
    int uid, {
    String mailbox = 'inbox',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/email/inbox/$uid',
      queryParameters: {'mailbox': mailbox},
    );
    return EmailMessageDetailModel.fromJson(response.data!);
  }

  Future<List<EmailThreadModel>> listThreads({
    int monthsBack = 6,
    int limit = 200,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/email/threads',
      queryParameters: {'months': monthsBack, 'limit': limit},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmailThreadModel.fromJson)
        .toList();
  }

  Future<EmailThreadDetailModel> getThread(
    String threadId, {
    int monthsBack = 6,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/email/threads/$threadId',
      queryParameters: {'months': monthsBack},
    );
    return EmailThreadDetailModel.fromJson(response.data!);
  }
}
