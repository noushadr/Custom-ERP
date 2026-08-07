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
