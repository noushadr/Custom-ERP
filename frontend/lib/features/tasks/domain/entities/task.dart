/// A task's [assigneeEmployeeId] is nullable — a task can be assigned to a
/// whole team ([departmentId] set, no assignee yet) until either that
/// team's head picks a specific member or a member claims it themself.
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
    required this.progressRemarks,
    required this.completedAt,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final String? description;

  /// Null until the task is claimed by, or assigned to, a specific person.
  final String? assigneeEmployeeId;
  final String? assigneeName;
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

  /// Free-text progress notes, settable by the assignee.
  final String? progressRemarks;
  final DateTime? completedAt;

  /// Optional link to a Clients & Projects project.
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// How many comments/progress updates this task has — shown as a small
  /// count badge on the board card, same idea as a Trello/Linear card.
  final int commentCount;

  /// Set only by a `tasks.manage` holder (HR/Admin) — hidden from the
  /// normal board/lists by default, revealed via the Archived toggle.
  /// Independent of [status]: an archived task keeps whatever status it had.
  final bool isArchived;

  /// Not yet picked up by anyone — assigned to a team, no assignee.
  bool get isUnclaimed => assigneeEmployeeId == null;
}
