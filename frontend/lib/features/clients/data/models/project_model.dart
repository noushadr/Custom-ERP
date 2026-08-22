import '../../../../core/config/app_config.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_refs.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.clientId,
    required super.clientName,
    required super.name,
    required super.type,
    required super.status,
    required super.startDate,
    required super.endDate,
    required super.renewalDate,
    required super.notes,
    required super.assignedEmployees,
    required super.targetDepartments,
    required super.services,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    clientName: json['clientName'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    status: json['status'] as String,
    startDate: json['startDate'] as String,
    endDate: json['endDate'] as String?,
    renewalDate: json['renewalDate'] as String?,
    notes: json['notes'] as String?,
    assignedEmployees: (json['assignedEmployees'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (e) => ProjectEmployeeRef(
            id: e['id'] as String,
            fullName: e['fullName'] as String,
            photoUrl: _resolvePhotoUrl(e['photoUrl'] as String?),
          ),
        )
        .toList(),
    targetDepartments: (json['targetDepartments'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (d) =>
              ProjectDepartmentRef(id: d['id'] as String, name: d['name'] as String),
        )
        .toList(),
    services: (json['services'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (s) =>
              ProjectServiceRef(id: s['id'] as String, name: s['name'] as String),
        )
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  /// Same convention as EmployeeModel/TaskModel's `_resolvePhotoUrl`.
  static String? _resolvePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }
}
