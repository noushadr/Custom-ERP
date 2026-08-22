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
    required this.endDate,
    required this.renewalDate,
    required this.notes,
    required this.packageName,
    required this.backlinksTarget,
    required this.seoSheetName,
    required this.projectFolderName,
    required this.workingEmailAccount,
    required this.ahrefsAccount,
    required this.assignedEmployees,
    required this.targetDepartments,
    required this.services,
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
  final String? endDate;
  final String? renewalDate;
  final String? notes;

  /// Free-text tier label (e.g. "GROWTH +", "VALUE").
  final String? packageName;

  /// Free-text monthly backlink target — a number or a "min/max" range.
  final String? backlinksTarget;

  /// Title of the external SEO tracking sheet for this project.
  final String? seoSheetName;

  /// Name of the external project-details folder.
  final String? projectFolderName;

  /// Reference-only email/username — never paired with a stored password.
  final String? workingEmailAccount;

  /// Reference-only email/username for this project's Ahrefs account.
  final String? ahrefsAccount;

  final List<ProjectEmployeeRef> assignedEmployees;
  final List<ProjectDepartmentRef> targetDepartments;
  final List<ProjectServiceRef> services;

  final DateTime createdAt;
  final DateTime updatedAt;
}
