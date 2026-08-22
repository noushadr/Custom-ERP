import '../../domain/entities/employee_checklist_item.dart';

class EmployeeChecklistItemModel extends EmployeeChecklistItem {
  const EmployeeChecklistItemModel({
    required super.id,
    required super.employeeId,
    super.templateItemId,
    required super.type,
    required super.title,
    required super.sortOrder,
    required super.isCompleted,
    super.completedAt,
    super.completedByName,
    super.note,
  });

  factory EmployeeChecklistItemModel.fromJson(Map<String, dynamic> json) =>
      EmployeeChecklistItemModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        templateItemId: json['templateItemId'] as String?,
        type: json['type'] as String,
        title: json['title'] as String,
        sortOrder: json['sortOrder'] as int,
        isCompleted: json['isCompleted'] as bool,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        completedByName: json['completedByName'] as String?,
        note: json['note'] as String?,
      );
}
