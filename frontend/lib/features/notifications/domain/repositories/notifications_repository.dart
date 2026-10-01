import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> getMine({bool unreadOnly = false});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
