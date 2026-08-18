import 'package:dio/dio.dart';
import '../../domain/entities/notice.dart';
import '../../domain/exceptions/notice_exception.dart';
import '../../domain/repositories/notice_repository.dart';
import '../datasources/notice_remote_data_source.dart';

class NoticeRepositoryImpl implements NoticeRepository {
  const NoticeRepositoryImpl(this._remoteDataSource);

  final NoticeRemoteDataSource _remoteDataSource;

  @override
  Future<List<Notice>> getAll() => _guard(() => _remoteDataSource.getAll());

  @override
  Future<Notice> create({required String title, required String body}) =>
      _guard(() => _remoteDataSource.create(title: title, body: body));

  @override
  Future<Notice> update(String id, {String? title, String? body}) =>
      _guard(() => _remoteDataSource.update(id, title: title, body: body));

  @override
  Future<void> delete(String id) => _guard(() => _remoteDataSource.delete(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw NoticeException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'Not found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
