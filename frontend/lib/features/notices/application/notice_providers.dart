import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/notice_remote_data_source.dart';
import '../data/repositories/notice_repository_impl.dart';
import '../domain/entities/notice.dart';
import '../domain/repositories/notice_repository.dart';

final noticeRemoteDataSourceProvider = Provider<NoticeRemoteDataSource>(
  (ref) => NoticeRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final noticeRepositoryProvider = Provider<NoticeRepository>(
  (ref) => NoticeRepositoryImpl(ref.watch(noticeRemoteDataSourceProvider)),
);

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// see the longer explanation in employee_providers.dart.
final noticeListProvider = FutureProvider.autoDispose<List<Notice>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(noticeRepositoryProvider).getAll();
});

/// Every notice including expired ones, for whoever manages notices — so they
/// can still edit, extend or delete one after it has stopped showing to staff.
/// Only watched when the viewer holds `notices.manage` (the server ignores the
/// flag for anyone else). [noticeListProvider] stays active-only, which is what
/// the notification bell and the staff view use.
final manageableNoticeListProvider = FutureProvider.autoDispose<List<Notice>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(noticeRepositoryProvider).getAll(includeExpired: true);
});

/// Refetches both notice lists — call after posting, editing or deleting.
void refreshNotices(WidgetRef ref) {
  ref.invalidate(noticeListProvider);
  ref.invalidate(manageableNoticeListProvider);
}

/// Set by the notification bell when the viewer taps a specific notice, so
/// the dashboard's notices section can jump to whichever page that notice
/// falls on instead of just showing page 1 regardless of where it actually
/// is. Read once and left as-is afterward — see CompanyNoticesSection.
final focusedNoticeIdProvider = StateProvider<String?>((ref) => null);
