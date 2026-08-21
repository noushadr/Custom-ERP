import '../entities/task.dart';
import '../entities/task_audit_log_entry.dart';
import '../entities/task_comment.dart';

abstract interface class TaskRepository {
  /// "My Tasks" — assigned to the caller.
  Future<List<Task>> getMyTasks();

  /// "Assigned Tasks" — created by the caller.
  Future<List<Task>> getTasksAssignedByMe();

  /// "Team Tasks" — company-wide for a `tasks.manage` holder, or the
  /// caller's headed department(s) for a department head; empty otherwise.
  Future<List<Task>> getTeamTasks();

  /// Throws [TaskException] if the caller isn't allowed to view this task.
  Future<Task> getTask(String id);

  Future<List<TaskAuditLogEntry>> getHistory(String id);

  Future<List<TaskComment>> getComments(String id);

  Future<TaskComment> addComment(String id, String body);

  /// Clients & Projects' view of "which tasks belong to this project" —
  /// requires `clients.manage`.
  Future<List<Task>> getTasksByProject(String projectId);

  /// Requires `tasks.manage` or headship of the assignee's department.
  Future<Task> createTask({
    required String title,
    String? description,
    required String assigneeEmployeeId,
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

  /// The assignee, the assigner, a department head, or a `tasks.manage`
  /// holder may change status.
  Future<Task> updateStatus(String id, String status);
}
