/// A single-assignee task. `departmentId`/`departmentName` reflect the
/// assignee's current department (derived server-side, never stored) —
/// always current, even after a reassignment.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeEmployeeId,
    required this.assigneeName,
    required this.assigneePhotoUrl,
    required this.departmentId,
    required this.departmentName,
    required this.assignedByUserId,
    required this.assignedByName,
    required this.assignedByPhotoUrl,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.completedAt,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String assigneeEmployeeId;
  final String assigneeName;
  final String? assigneePhotoUrl;
  final String? departmentId;
  final String? departmentName;
  final String assignedByUserId;
  final String assignedByName;
  final String? assignedByPhotoUrl;

  /// One of TaskPriority's values.
  final String priority;

  /// ISO date (yyyy-MM-dd).
  final String dueDate;

  /// One of TaskStatus's values.
  final String status;
  final DateTime? completedAt;

  /// Optional link to a Clients & Projects project.
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
