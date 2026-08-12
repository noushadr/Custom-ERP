import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.name,
    super.category,
    super.serialNumber,
    required super.status,
    required super.assignedEmployeeId,
    super.assignedAt,
    super.notes,
    required super.createdAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String?,
    serialNumber: json['serialNumber'] as String?,
    status: json['status'] as String,
    assignedEmployeeId: json['assignedEmployeeId'] as String?,
    assignedAt: json['assignedAt'] == null
        ? null
        : DateTime.parse(json['assignedAt'] as String),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
