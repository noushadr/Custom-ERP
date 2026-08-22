import '../../domain/entities/service.dart';

class ServiceModel extends Service {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.isArchived,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    isArchived: json['isArchived'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
