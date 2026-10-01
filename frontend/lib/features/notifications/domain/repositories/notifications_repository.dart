import '../entities/app_notification.dart';
import '../entities/notification_mute_preference.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> getMine({bool unreadOnly = false});
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<List<NotificationMutePreference>> getMutePreferences();
  Future<void> setMutePreference(String category, bool muted);
}
