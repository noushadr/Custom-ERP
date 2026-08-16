import '../../domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    required super.departmentId,
    super.departmentName,
    super.leadEmployeeId,
    super.isArchived,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      departmentId: json['departmentId'] as String,
      departmentName: department?['name'] as String?,
      leadEmployeeId: json['leadEmployeeId'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}
