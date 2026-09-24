import '../../../../shared/utils/photo_url.dart';
import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.assigneeEmployeeId,
    required super.assigneeName,
    required super.assigneePhotoUrl,
    required super.departmentId,
    required super.departmentName,
    required super.assignedByUserId,
    required super.assignedByName,
    required super.assignedByPhotoUrl,
    required super.priority,
    required super.dueDate,
    required super.status,
    required super.progressRemarks,
    required super.completedAt,
    required super.projectId,
    required super.createdAt,
    required super.updatedAt,
    required super.commentCount,
    super.isArchived,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    assigneeEmployeeId: json['assigneeEmployeeId'] as String?,
    assigneeName: json['assigneeName'] as String?,
    assigneePhotoUrl: resolvePhotoUrl(json['assigneePhotoUrl'] as String?),
    departmentId: json['departmentId'] as String?,
    departmentName: json['departmentName'] as String?,
    assignedByUserId: json['assignedByUserId'] as String,
    assignedByName: json['assignedByName'] as String,
    assignedByPhotoUrl: resolvePhotoUrl(json['assignedByPhotoUrl'] as String?),
    priority: json['priority'] as String,
    dueDate: json['dueDate'] as String,
    status: json['status'] as String,
    progressRemarks: json['progressRemarks'] as String?,
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    projectId: json['projectId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    commentCount: json['commentCount'] as int? ?? 0,
    isArchived: json['isArchived'] as bool? ?? false,
  );
}
