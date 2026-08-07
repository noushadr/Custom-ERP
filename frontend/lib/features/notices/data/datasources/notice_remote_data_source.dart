import 'package:dio/dio.dart';
import '../models/notice_model.dart';

class NoticeRemoteDataSource {
  const NoticeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NoticeModel>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/notices');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(NoticeModel.fromJson)
        .toList();
  }

  Future<NoticeModel> create({
    required String title,
    required String body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notices',
      data: {'title': title, 'body': body},
    );
    return NoticeModel.fromJson(response.data!);
  }
}
