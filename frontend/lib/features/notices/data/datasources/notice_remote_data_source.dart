import 'package:dio/dio.dart';
import '../../domain/entities/notice_display_duration.dart';
import '../models/notice_model.dart';

class NoticeRemoteDataSource {
  const NoticeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NoticeModel>> getAll({bool includeExpired = false}) async {
    final response = await _dio.get<List<dynamic>>(
      '/notices',
      queryParameters: {if (includeExpired) 'includeExpired': 'true'},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(NoticeModel.fromJson)
        .toList();
  }

  Future<NoticeModel> create({
    required String title,
    required String body,
    NoticeDisplayDuration? displayDuration,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notices',
      data: {
        'title': title,
        'body': body,
        'displayDuration': ?displayDuration?.apiValue,
      },
    );
    return NoticeModel.fromJson(response.data!);
  }

  Future<NoticeModel> update(
    String id, {
    String? title,
    String? body,
    NoticeDisplayDuration? displayDuration,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/notices/$id',
      data: {
        'title': ?title,
        'body': ?body,
        'displayDuration': ?displayDuration?.apiValue,
      },
    );
    return NoticeModel.fromJson(response.data!);
  }

  Future<void> delete(String id) => _dio.delete<void>('/notices/$id');
}
