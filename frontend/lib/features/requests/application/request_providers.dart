import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/application/auth_providers.dart';
import '../data/datasources/request_remote_data_source.dart';
import '../data/repositories/request_repository_impl.dart';
import '../domain/entities/employee_request.dart';
import '../domain/repositories/request_repository.dart';

final requestRemoteDataSourceProvider = Provider<RequestRemoteDataSource>(
  (ref) => RequestRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepositoryImpl(ref.watch(requestRemoteDataSourceProvider)),
);

// Every provider below re-watches authControllerProvider purely to create a
// dependency edge, so switching identity (impersonate/returnToAdmin/logout)
// triggers a refetch — see the longer explanation in employee_providers.dart.

final myRequestsProvider = FutureProvider.autoDispose<List<EmployeeRequest>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(requestRepositoryProvider).getMine();
});

final pendingManagerApprovalRequestsProvider =
    FutureProvider.autoDispose<List<EmployeeRequest>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(requestRepositoryProvider).getPendingManagerApproval();
    });

final pendingHrApprovalRequestsProvider =
    FutureProvider.autoDispose<List<EmployeeRequest>>((ref) {
      ref.watch(authControllerProvider);
      return ref.watch(requestRepositoryProvider).getPendingHrApproval();
    });
