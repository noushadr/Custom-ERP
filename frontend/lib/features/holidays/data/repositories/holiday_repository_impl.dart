import 'package:dio/dio.dart';
import '../../domain/entities/holiday.dart';
import '../../domain/exceptions/holiday_exception.dart';
import '../../domain/repositories/holiday_repository.dart';
import '../datasources/holiday_remote_data_source.dart';

class HolidayRepositoryImpl implements HolidayRepository {
  const HolidayRepositoryImpl(this._remoteDataSource);

  final HolidayRemoteDataSource _remoteDataSource;

  @override
  Future<List<Holiday>> getAll({int? year}) =>
      _guard(() => _remoteDataSource.getAll(year: year));

  @override
  Future<Holiday> create({required String name, required String date}) =>
      _guard(() => _remoteDataSource.create(name: name, date: date));

  @override
  Future<Holiday> update(String id, {String? name, String? date}) =>
      _guard(() => _remoteDataSource.update(id, name: name, date: date));

  @override
  Future<void> delete(String id) => _guard(() => _remoteDataSource.delete(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw HolidayException(_mapError(error));
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
