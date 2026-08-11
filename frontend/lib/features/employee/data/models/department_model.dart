import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({
    required super.id,
    required super.name,
    super.description,
    super.headEmployeeId,
    super.isArchived,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) =>
      DepartmentModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        headEmployeeId: json['headEmployeeId'] as String?,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}
