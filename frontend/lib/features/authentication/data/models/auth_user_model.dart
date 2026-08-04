import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.permissions,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    permissions: (json['permissions'] as List).cast<String>(),
  );
}
