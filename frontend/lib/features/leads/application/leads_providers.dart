import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/leads_remote_data_source.dart';
import '../data/repositories/leads_repository_impl.dart';
import '../domain/entities/lead.dart';
import '../domain/repositories/leads_repository.dart';

final leadsRemoteDataSourceProvider = Provider<LeadsRemoteDataSource>(
  (ref) => LeadsRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final leadsRepositoryProvider = Provider<LeadsRepository>(
  (ref) => LeadsRepositoryImpl(ref.watch(leadsRemoteDataSourceProvider)),
);

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// see the longer explanation in employee_providers.dart.
final leadsListProvider = FutureProvider.autoDispose.family<List<Lead>, bool>((
  ref,
  includeArchived,
) {
  ref.watch(authControllerProvider);
  return ref
      .watch(leadsRepositoryProvider)
      .getLeads(includeArchived: includeArchived);
});
