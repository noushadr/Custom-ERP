import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/notifications_remote_data_source.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/entities/app_notification.dart';
import '../domain/repositories/notifications_repository.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) =>
          NotificationsRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) =>
      NotificationsRepositoryImpl(ref.watch(notificationsRemoteDataSourceProvider)),
);

/// The viewer's own unread notifications — polled the same way every other
/// bell data source is (a plain FutureProvider re-fetched on invalidate),
/// not a live socket feed.
final myNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(notificationsRepositoryProvider).getMine(unreadOnly: true);
});
