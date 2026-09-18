import '../../../../shared/utils/photo_url.dart';
import '../../domain/entities/goal.dart';

class GoalModel extends Goal {
  const GoalModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    super.employeePhotoUrl,
    super.departmentId,
    super.departmentName,
    required super.title,
    super.description,
    required super.achievementPercentage,
    required super.createdByName,
    required super.createdAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    employeeName: json['employeeName'] as String,
    employeePhotoUrl: resolvePhotoUrl(json['employeePhotoUrl'] as String?),
    departmentId: json['departmentId'] as String?,
    departmentName: json['departmentName'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    achievementPercentage: json['achievementPercentage'] as int,
    createdByName: json['createdByName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
