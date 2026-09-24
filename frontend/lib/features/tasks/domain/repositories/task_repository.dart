import '../entities/task.dart';
import '../entities/task_audit_log_entry.dart';
import '../entities/task_comment.dart';

abstract interface class TaskRepository {
  /// "My Tasks" — assigned to the caller.
  Future<List<Task>> getMyTasks();

  /// "Assigned Tasks" — created by the caller.
  Future<List<Task>> getTasksAssignedByMe();

  /// "Task Board" — company-wide for a `tasks.manage` holder, or the
  /// caller's headed department(s) for a department head; empty otherwise.
  Future<List<Task>> getTeamTasks();

  /// Unclaimed tasks (assigned to a team, nobody picked yet) in the
  /// caller's own department — what they could accept.
  Future<List<Task>> getClaimableTasks();

  /// Throws [TaskException] if the caller isn't allowed to view this task.
  Future<Task> getTask(String id);

  Future<List<TaskAuditLogEntry>> getHistory(String id);

  Future<List<TaskComment>> getComments(String id);

  Future<TaskComment> addComment(String id, String body);

  /// Clients & Projects' view of "which tasks belong to this project" —
  /// requires `clients.manage`.
  Future<List<Task>> getTasksByProject(String projectId);

  /// Exactly one of [assigneeEmployeeId]/[departmentId] should be set.
  /// Assigning straight to an employee requires `tasks.manage` or headship
  /// of their department; assigning to a team needs neither — anyone can
  /// hand a task to a team, leaving the team to pick who does it.
  Future<Task> createTask({
    required String title,
    String? description,
    String? assigneeEmployeeId,
    String? departmentId,
    String? priority,
    required String dueDate,
    String? projectId,
  });

  /// Requires `tasks.manage`, being the assigner, or headship of the task's
  /// (current, and — on reassignment — new) department.
  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? assigneeEmployeeId,
    String? priority,
    String? dueDate,
    String? projectId,
  });

  /// The assignee's own self-service update — status, due date, and/or
  /// progress remarks — notifies whoever assigned the task. The assigner,
  /// a department head, or a `tasks.manage` holder may also call this.
  Future<Task> updateProgress(
    String id, {
    String? status,
    String? dueDate,
    String? progressRemarks,
  });

  /// Any member of the task's own team claiming it for themselves.
  Future<Task> claimTask(String id);

  /// The task's team head picking a specific member.
  Future<Task> assignTeamMember(String id, String employeeId);

  /// Archives/unarchives a task — requires `tasks.manage` (HR/Admin only).
  Future<Task> archiveTask(String id, {required bool isArchived});
}
