import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remoteDataSource);

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<List<AppNotification>> getMine({bool unreadOnly = false}) =>
      _remoteDataSource.getMine(unreadOnly: unreadOnly);

  @override
  Future<void> markRead(String id) => _remoteDataSource.markRead(id);

  @override
  Future<void> markAllRead() => _remoteDataSource.markAllRead();
}
