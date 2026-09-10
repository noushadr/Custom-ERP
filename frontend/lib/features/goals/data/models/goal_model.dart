import '../../../../core/config/app_config.dart';
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
    employeePhotoUrl: _resolvePhotoUrl(json['employeePhotoUrl'] as String?),
    departmentId: json['departmentId'] as String?,
    departmentName: json['departmentName'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    achievementPercentage: json['achievementPercentage'] as int,
    createdByName: json['createdByName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// The backend returns photo paths relative to itself (e.g.
  /// `/uploads/avatars/ZC-00001.jpg`) — resolve against our known API base,
  /// same as `EmployeeModel._resolvePhotoUrl`. Without this the Goals page
  /// avatar tried to load a bare relative path as a `NetworkImage`, which
  /// the browser can't resolve, and silently fell back to initials forever.
  static String? _resolvePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }
}
