import 'package:zera_erp/features/notifications/domain/entities/app_notification.dart';
import 'package:zera_erp/features/notifications/domain/entities/notification_mute_preference.dart';
import 'package:zera_erp/features/notifications/domain/repositories/notifications_repository.dart';

AppNotification buildTestAppNotification({
  String id = 'notification-1',
  String message = 'Something happened',
  String? linkTarget,
  String? linkEntityId,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    message: message,
    linkTarget: linkTarget,
    linkEntityId: linkEntityId,
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    this.notifications = const [],
    this.mutePreferences = const [],
  });

  final List<AppNotification> notifications;
  List<NotificationMutePreference> mutePreferences;

  String? lastMarkedReadId;
  bool markedAllRead = false;
  String? lastSetMuteCategory;
  bool? lastSetMuteValue;

  @override
  Future<List<AppNotification>> getMine({bool unreadOnly = false}) async =>
      unreadOnly
      ? notifications.where((n) => !n.isRead).toList()
      : notifications;

  @override
  Future<void> markRead(String id) async {
    lastMarkedReadId = id;
  }

  @override
  Future<void> markAllRead() async {
    markedAllRead = true;
  }

  @override
  Future<List<NotificationMutePreference>> getMutePreferences() async =>
      mutePreferences;

  @override
  Future<void> setMutePreference(String category, bool muted) async {
    lastSetMuteCategory = category;
    lastSetMuteValue = muted;
  }
}
