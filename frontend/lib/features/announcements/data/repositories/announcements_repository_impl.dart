import 'package:dio/dio.dart';
import '../../domain/entities/today_announcements.dart';
import '../../domain/exceptions/announcements_exception.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../datasources/announcements_remote_data_source.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  const AnnouncementsRepositoryImpl(this._remoteDataSource);

  final AnnouncementsRemoteDataSource _remoteDataSource;

  @override
  Future<TodayAnnouncements> getToday() => _guard(
    () => _remoteDataSource.getToday(),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AnnouncementsException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
