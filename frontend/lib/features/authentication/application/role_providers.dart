import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/role_remote_data_source.dart';
import '../data/repositories/role_repository_impl.dart';
import '../domain/entities/permission.dart';
import '../domain/entities/role.dart';
import '../domain/repositories/role_repository.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

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

/// Whether the current viewer holds every known permission — i.e. is
/// functionally a Super Admin regardless of which role they're actually
/// assigned. Mirrors the backend's own `RolesService.assertCanEditSuperAdminRole`
/// check exactly, so the Roles & Permissions UI can pre-emptively disable
/// what the server would reject anyway (editing the Super Admin role),
/// rather than let a `roles.manage` holder like HR/Manager fill out a whole
/// form only to hit a 403 on save.
final viewerIsUnrestrictedProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final authState = ref.watch(authControllerProvider);
  final authUser = authState is AuthAuthenticated ? authState.user : null;
  if (authUser == null) return false;

  final permissions = await ref.watch(permissionsProvider.future);
  return permissions.every((permission) => authUser.hasPermission(permission.key));
});
