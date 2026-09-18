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
  String? assigneeEmployeeId = 'employee-1',
  String? assigneeName = 'Jane Doe',
  String? assigneePhotoUrl,
  String? departmentId = 'dept-1',
  String? departmentName = 'Engineering',
  String assignedByUserId = 'manager-user-1',
  String assignedByName = 'Manager Person',
  String? assignedByPhotoUrl,
  String priority = TaskPriority.medium,
  String dueDate = '2026-12-01',
  String status = TaskStatus.todo,
  String? progressRemarks,
  DateTime? completedAt,
  String? projectId,
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
    progressRemarks: progressRemarks,
    completedAt: completedAt,
    projectId: projectId,
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
    this.claimableTasks = const [],
    this.taskById,
    this.history = const [],
    this.comments = const [],
    this.createTaskResult,
    this.updateTaskResult,
    this.updateProgressResult,
    this.claimTaskResult,
    this.assignTeamMemberResult,
    this.addCommentResult,
    this.createTaskError,
    this.updateTaskError,
    this.updateProgressError,
    this.claimTaskError,
    this.assignTeamMemberError,
    this.getTaskError,
    this.tasksByProject = const [],
  });

  final List<Task> myTasks;
  final List<Task> tasksAssignedByMe;
  final List<Task> teamTasks;
  final List<Task> claimableTasks;
  final List<Task> tasksByProject;
  final Task? taskById;
  final List<TaskAuditLogEntry> history;
  final List<TaskComment> comments;
  final Task? createTaskResult;
  final Task? updateTaskResult;
  final Task? updateProgressResult;
  final Task? claimTaskResult;
  final Task? assignTeamMemberResult;
  final TaskComment? addCommentResult;
  final Object? createTaskError;
  final Object? updateTaskError;
  final Object? updateProgressError;
  final Object? claimTaskError;
  final Object? assignTeamMemberError;
  final Object? getTaskError;

  String? lastCreatedTitle;
  String? lastCreatedAssigneeEmployeeId;
  String? lastCreatedDepartmentId;
  String? lastCreatedPriority;
  String? lastCreatedDueDate;

  String? lastUpdatedId;
  String? lastUpdatedTitle;
  String? lastUpdatedAssigneeEmployeeId;
  String? lastUpdatedPriority;

  String? lastProgressUpdatedId;
  String? lastProgressUpdatedStatus;
  String? lastProgressUpdatedDueDate;
  String? lastProgressUpdatedRemarks;

  String? lastClaimedId;

  String? lastAssignedMemberTaskId;
  String? lastAssignedMemberEmployeeId;

  String? lastCommentedId;
  String? lastCommentBody;

  @override
  Future<List<Task>> getMyTasks() async => myTasks;

  @override
  Future<List<Task>> getTasksAssignedByMe() async => tasksAssignedByMe;

  @override
  Future<List<Task>> getTeamTasks() async => teamTasks;

  @override
  Future<List<Task>> getClaimableTasks() async => claimableTasks;

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
  Future<List<Task>> getTasksByProject(String projectId) async =>
      tasksByProject;

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    String? assigneeEmployeeId,
    String? departmentId,
    String? priority,
    required String dueDate,
    String? projectId,
  }) async {
    lastCreatedTitle = title;
    lastCreatedAssigneeEmployeeId = assigneeEmployeeId;
    lastCreatedDepartmentId = departmentId;
    lastCreatedPriority = priority;
    lastCreatedDueDate = dueDate;
    if (createTaskError != null) throw createTaskError!;
    return createTaskResult ??
        buildTestTask(title: title, projectId: projectId);
  }

  @override
  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? assigneeEmployeeId,
    String? priority,
    String? dueDate,
    String? projectId,
  }) async {
    lastUpdatedId = id;
    lastUpdatedTitle = title;
    lastUpdatedAssigneeEmployeeId = assigneeEmployeeId;
    lastUpdatedPriority = priority;
    if (updateTaskError != null) throw updateTaskError!;
    return updateTaskResult ?? buildTestTask(id: id, projectId: projectId);
  }

  @override
  Future<Task> updateProgress(
    String id, {
    String? status,
    String? dueDate,
    String? progressRemarks,
  }) async {
    lastProgressUpdatedId = id;
    lastProgressUpdatedStatus = status;
    lastProgressUpdatedDueDate = dueDate;
    lastProgressUpdatedRemarks = progressRemarks;
    if (updateProgressError != null) throw updateProgressError!;
    return updateProgressResult ??
        buildTestTask(
          id: id,
          status: status ?? TaskStatus.todo,
          dueDate: dueDate ?? '2026-12-01',
          progressRemarks: progressRemarks,
        );
  }

  @override
  Future<Task> claimTask(String id) async {
    lastClaimedId = id;
    if (claimTaskError != null) throw claimTaskError!;
    return claimTaskResult ?? buildTestTask(id: id);
  }

  @override
  Future<Task> assignTeamMember(String id, String employeeId) async {
    lastAssignedMemberTaskId = id;
    lastAssignedMemberEmployeeId = employeeId;
    if (assignTeamMemberError != null) throw assignTeamMemberError!;
    return assignTeamMemberResult ??
        buildTestTask(id: id, assigneeEmployeeId: employeeId);
  }
}
