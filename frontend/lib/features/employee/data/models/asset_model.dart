import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.name,
    required super.status,
    required super.assignedEmployeeId,
    super.assignedAt,
    super.value,
    required super.createdAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
    id: json['id'] as String,
    name: json['name'] as String,
    status: json['status'] as String,
    assignedEmployeeId: json['assignedEmployeeId'] as String?,
    assignedAt: json['assignedAt'] == null
        ? null
        : DateTime.parse(json['assignedAt'] as String),
    value: json['value'] == null
        ? null
        : double.parse(json['value'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
