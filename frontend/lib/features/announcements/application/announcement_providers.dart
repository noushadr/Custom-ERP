import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/announcements_remote_data_source.dart';
import '../data/repositories/announcements_repository_impl.dart';
import '../domain/entities/today_announcements.dart';
import '../domain/repositories/announcements_repository.dart';

final announcementsRemoteDataSourceProvider =
    Provider<AnnouncementsRemoteDataSource>(
      (ref) =>
          AnnouncementsRemoteDataSource(ref.watch(dioClientProvider).dio),
    );

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => AnnouncementsRepositoryImpl(
    ref.watch(announcementsRemoteDataSourceProvider),
  ),
);

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// see the longer explanation in employee_providers.dart.
final todayAnnouncementsProvider = FutureProvider.autoDispose<
  TodayAnnouncements
>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(announcementsRepositoryProvider).getToday();
});
