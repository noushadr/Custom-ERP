import '../../domain/entities/permission.dart';

class PermissionModel extends Permission {
  const PermissionModel({required super.key, super.description});

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        key: json['key'] as String,
        description: json['description'] as String?,
      );
}
