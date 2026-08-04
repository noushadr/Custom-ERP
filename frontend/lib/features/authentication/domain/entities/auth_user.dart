class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final String id;
  final String email;
  final String role;
  final List<String> permissions;

  bool hasPermission(String permission) => permissions.contains(permission);
}
