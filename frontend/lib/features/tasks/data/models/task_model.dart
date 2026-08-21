import '../../../../core/config/app_config.dart';
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
    required super.completedAt,
    required super.projectId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    assigneeEmployeeId: json['assigneeEmployeeId'] as String,
    assigneeName: json['assigneeName'] as String,
    assigneePhotoUrl: _resolvePhotoUrl(json['assigneePhotoUrl'] as String?),
    departmentId: json['departmentId'] as String?,
    departmentName: json['departmentName'] as String?,
    assignedByUserId: json['assignedByUserId'] as String,
    assignedByName: json['assignedByName'] as String,
    assignedByPhotoUrl: _resolvePhotoUrl(
      json['assignedByPhotoUrl'] as String?,
    ),
    priority: json['priority'] as String,
    dueDate: json['dueDate'] as String,
    status: json['status'] as String,
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    projectId: json['projectId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  /// The backend returns photo paths relative to itself (e.g.
  /// `/uploads/avatars/ZC-00001.jpg`) so the API response stays portable
  /// across environments; resolve it against our known API base here — same
  /// convention as EmployeeModel's own `_resolvePhotoUrl`.
  static String? _resolvePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }
}
