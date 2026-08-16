class Role {
  const Role({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
    required this.permissions,
    required this.userCount,
  });

  final String id;
  final String name;
  final String? description;

  /// True for the four built-in roles (Super Admin, HR/Manager, Team Lead,
  /// Employee) — these can't be renamed or deleted, but their permissions
  /// can still be edited.
  final bool isSystem;

  /// Permission keys granted to this role.
  final List<String> permissions;

  /// How many employees currently have this role — a role with any can't
  /// be deleted until they're reassigned.
  final int userCount;
}
