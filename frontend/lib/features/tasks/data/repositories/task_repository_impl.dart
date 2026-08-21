import 'package:dio/dio.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_audit_log_entry.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/exceptions/task_exception.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<Task>> getMyTasks() => _guard(_remoteDataSource.getMyTasks);

  @override
  Future<List<Task>> getTasksAssignedByMe() =>
      _guard(_remoteDataSource.getTasksAssignedByMe);

  @override
  Future<List<Task>> getTeamTasks() => _guard(_remoteDataSource.getTeamTasks);

  @override
  Future<Task> getTask(String id) => _guard(() => _remoteDataSource.getTask(id));

  @override
  Future<List<TaskAuditLogEntry>> getHistory(String id) =>
      _guard(() => _remoteDataSource.getHistory(id));

  @override
  Future<List<TaskComment>> getComments(String id) =>
      _guard(() => _remoteDataSource.getComments(id));

  @override
  Future<TaskComment> addComment(String id, String body) =>
      _guard(() => _remoteDataSource.addComment(id, body));

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    required String assigneeEmployeeId,
    String? priority,
    required String dueDate,
  }) => _guard(
    () => _remoteDataSource.createTask(
      title: title,
      description: description,
      assigneeEmployeeId: assigneeEmployeeId,
      priority: priority,
      dueDate: dueDate,
    ),
  );

  @override
  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? assigneeEmployeeId,
    String? priority,
    String? dueDate,
  }) => _guard(
    () => _remoteDataSource.updateTask(
      id,
      title: title,
      description: description,
      assigneeEmployeeId: assigneeEmployeeId,
      priority: priority,
      dueDate: dueDate,
    ),
  );

  @override
  Future<Task> updateStatus(String id, String status) =>
      _guard(() => _remoteDataSource.updateStatus(id, status));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw TaskException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
