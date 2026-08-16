import '../../domain/entities/role.dart';

class RoleModel extends Role {
  const RoleModel({
    required super.id,
    required super.name,
    super.description,
    required super.isSystem,
    required super.permissions,
    required super.userCount,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    isSystem: json['isSystem'] as bool,
    permissions: (json['permissions'] as List<dynamic>).cast<String>(),
    userCount: json['userCount'] as int,
  );
}
