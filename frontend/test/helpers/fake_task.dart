import 'package:zera_erp/features/tasks/domain/entities/task.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_audit_log_entry.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_comment.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_priority.dart';
import 'package:zera_erp/features/tasks/domain/entities/task_status.dart';
import 'package:zera_erp/features/tasks/domain/repositories/task_repository.dart';

Task buildTestTask({
  String id = 'task-1',
  String title = 'Write report',
  String? description = 'Quarterly summary',
  String assigneeEmployeeId = 'employee-1',
  String assigneeName = 'Jane Doe',
  String? assigneePhotoUrl,
  String? departmentId = 'dept-1',
  String? departmentName = 'Engineering',
  String assignedByUserId = 'manager-user-1',
  String assignedByName = 'Manager Person',
  String? assignedByPhotoUrl,
  String priority = TaskPriority.medium,
  String dueDate = '2026-12-01',
  String status = TaskStatus.todo,
  DateTime? completedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    assigneeEmployeeId: assigneeEmployeeId,
    assigneeName: assigneeName,
    assigneePhotoUrl: assigneePhotoUrl,
    departmentId: departmentId,
    departmentName: departmentName,
    assignedByUserId: assignedByUserId,
    assignedByName: assignedByName,
    assignedByPhotoUrl: assignedByPhotoUrl,
    priority: priority,
    dueDate: dueDate,
    status: status,
    completedAt: completedAt,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

TaskComment buildTestTaskComment({
  String id = 'comment-1',
  String authorName = 'Jane Doe',
  String body = 'Looks good.',
  DateTime? createdAt,
}) {
  return TaskComment(
    id: id,
    authorName: authorName,
    body: body,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

TaskAuditLogEntry buildTestTaskAuditLogEntry({
  String id = 'log-1',
  String actorName = 'Jane Doe',
  String fieldLabel = 'Created',
  String? oldValue,
  String? newValue = 'Assigned to Jane Doe',
  DateTime? createdAt,
}) {
  return TaskAuditLogEntry(
    id: id,
    actorName: actorName,
    fieldLabel: fieldLabel,
    oldValue: oldValue,
    newValue: newValue,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    this.myTasks = const [],
    this.tasksAssignedByMe = const [],
    this.teamTasks = const [],
    this.taskById,
    this.history = const [],
    this.comments = const [],
    this.createTaskResult,
    this.updateTaskResult,
    this.updateStatusResult,
    this.addCommentResult,
    this.createTaskError,
    this.updateTaskError,
    this.updateStatusError,
    this.getTaskError,
  });

  final List<Task> myTasks;
  final List<Task> tasksAssignedByMe;
  final List<Task> teamTasks;
  final Task? taskById;
  final List<TaskAuditLogEntry> history;
  final List<TaskComment> comments;
  final Task? createTaskResult;
  final Task? updateTaskResult;
  final Task? updateStatusResult;
  final TaskComment? addCommentResult;
  final Object? createTaskError;
  final Object? updateTaskError;
  final Object? updateStatusError;
  final Object? getTaskError;

  String? lastCreatedTitle;
  String? lastCreatedAssigneeEmployeeId;
  String? lastCreatedPriority;
  String? lastCreatedDueDate;

  String? lastUpdatedId;
  String? lastUpdatedTitle;
  String? lastUpdatedAssigneeEmployeeId;

  String? lastStatusUpdatedId;
  String? lastStatusUpdatedStatus;

  String? lastCommentedId;
  String? lastCommentBody;

  @override
  Future<List<Task>> getMyTasks() async => myTasks;

  @override
  Future<List<Task>> getTasksAssignedByMe() async => tasksAssignedByMe;

  @override
  Future<List<Task>> getTeamTasks() async => teamTasks;

  @override
  Future<Task> getTask(String id) async {
    if (getTaskError != null) throw getTaskError!;
    return taskById ?? buildTestTask(id: id);
  }

  @override
  Future<List<TaskAuditLogEntry>> getHistory(String id) async => history;

  @override
  Future<List<TaskComment>> getComments(String id) async => comments;

  @override
  Future<TaskComment> addComment(String id, String body) async {
    lastCommentedId = id;
    lastCommentBody = body;
    return addCommentResult ?? buildTestTaskComment(body: body);
  }

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    required String assigneeEmployeeId,
    String? priority,
    required String dueDate,
  }) async {
    lastCreatedTitle = title;
    lastCreatedAssigneeEmployeeId = assigneeEmployeeId;
    lastCreatedPriority = priority;
    lastCreatedDueDate = dueDate;
    if (createTaskError != null) throw createTaskError!;
    return createTaskResult ?? buildTestTask(title: title);
  }

  @override
  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? assigneeEmployeeId,
    String? priority,
    String? dueDate,
  }) async {
    lastUpdatedId = id;
    lastUpdatedTitle = title;
    lastUpdatedAssigneeEmployeeId = assigneeEmployeeId;
    if (updateTaskError != null) throw updateTaskError!;
    return updateTaskResult ?? buildTestTask(id: id);
  }

  @override
  Future<Task> updateStatus(String id, String status) async {
    lastStatusUpdatedId = id;
    lastStatusUpdatedStatus = status;
    if (updateStatusError != null) throw updateStatusError!;
    return updateStatusResult ?? buildTestTask(id: id, status: status);
  }
}
