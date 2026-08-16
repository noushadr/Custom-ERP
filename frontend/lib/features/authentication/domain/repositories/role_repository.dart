import '../entities/permission.dart';
import '../entities/role.dart';

abstract interface class RoleRepository {
  /// Throws [AuthException] on failure. Requires `roles.manage`.
  Future<List<Role>> getRoles();

  /// Requires `roles.manage`.
  Future<List<Permission>> getPermissions();

  /// Requires `roles.manage`.
  Future<Role> createRole({
    required String name,
    String? description,
    required List<String> permissionKeys,
  });

  /// Requires `roles.manage`. [name] can't be changed on a system role.
  Future<Role> updateRole(
    String id, {
    String? name,
    String? description,
    List<String>? permissionKeys,
  });

  /// Requires `roles.manage`. Fails for system roles or roles that still
  /// have employees assigned.
  Future<void> deleteRole(String id);
}
