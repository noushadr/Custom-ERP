import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/role_remote_data_source.dart';
import '../data/repositories/role_repository_impl.dart';
import '../domain/entities/permission.dart';
import '../domain/entities/role.dart';
import '../domain/repositories/role_repository.dart';
import 'auth_providers.dart';

final roleRemoteDataSourceProvider = Provider<RoleRemoteDataSource>(
  (ref) => RoleRemoteDataSource(ref.watch(dioClientProvider).dio),
);

final roleRepositoryProvider = Provider<RoleRepository>(
  (ref) => RoleRepositoryImpl(ref.watch(roleRemoteDataSourceProvider)),
);

// Re-watches authControllerProvider purely to create a dependency edge, so
// switching identity (impersonate/returnToAdmin/logout) triggers a refetch —
// see the longer explanation in employee_providers.dart.
final rolesProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(roleRepositoryProvider).getRoles();
});

final permissionsProvider = FutureProvider.autoDispose<List<Permission>>((
  ref,
) {
  ref.watch(authControllerProvider);
  return ref.watch(roleRepositoryProvider).getPermissions();
});
