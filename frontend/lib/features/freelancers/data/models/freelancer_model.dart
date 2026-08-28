import '../../domain/entities/freelancer.dart';

class FreelancerModel extends Freelancer {
  const FreelancerModel({
    required super.id,
    required super.fullName,
    required super.role,
    required super.notes,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FreelancerModel.fromJson(Map<String, dynamic> json) =>
      FreelancerModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String?,
        notes: json['notes'] as String?,
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
