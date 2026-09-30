import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/email_remote_data_source.dart';
import '../data/repositories/email_repository_impl.dart';
import '../domain/entities/email_account.dart';
import '../domain/entities/inbox_message.dart' show EmailThread, EmailThreadDetail;
import '../domain/repositories/email_repository.dart';

final emailRemoteDataSourceProvider = Provider<EmailRemoteDataSource>(
  (ref) => EmailRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final emailRepositoryProvider = Provider<EmailRepository>(
  (ref) => EmailRepositoryImpl(ref.watch(emailRemoteDataSourceProvider)),
);

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// same convention as goal_providers.dart.

final myEmailAccountProvider = FutureProvider.autoDispose<EmailAccount?>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(emailRepositoryProvider).getMyAccount();
});

/// Every conversation across Inbox + Sent, fetched once and filtered
/// client-side per tab (see `EmailPage`) — a single IMAP round trip already
/// covers both folders.
final emailThreadsProvider = FutureProvider.autoDispose<List<EmailThread>>((
  ref,
) async {
  final account = await ref.watch(myEmailAccountProvider.future);
  if (account == null) return [];
  return ref.watch(emailRepositoryProvider).listThreads();
});

final emailThreadDetailProvider = FutureProvider.autoDispose
    .family<EmailThreadDetail, String>(
      (ref, threadId) =>
          ref.watch(emailRepositoryProvider).getThread(threadId),
    );
