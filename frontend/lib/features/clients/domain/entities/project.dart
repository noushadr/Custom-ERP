import 'project_refs.dart';

class Project {
  const Project({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.name,
    required this.type,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.renewalDate,
    required this.notes,
    this.accountManager,
    required this.assignedEmployees,
    required this.targetDepartments,
    required this.services,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String name;

  /// One of ProjectType's values.
  final String type;

  /// One of ProjectStatus's values.
  final String status;

  /// ISO date (yyyy-MM-dd).
  final String startDate;

  /// The project's deadline (ISO date). Every project has this or a
  /// [renewalDate].
  final String? endDate;
  final String? renewalDate;
  final String? notes;

  /// The project's owner — always one of [assignedEmployees].
  final ProjectEmployeeRef? accountManager;

  final List<ProjectEmployeeRef> assignedEmployees;
  final List<ProjectDepartmentRef> targetDepartments;
  final List<ProjectServiceRef> services;

  final bool isArchived;

  final DateTime createdAt;
  final DateTime updatedAt;
}
