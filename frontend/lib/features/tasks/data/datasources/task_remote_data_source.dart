import 'package:dio/dio.dart';
import '../models/task_audit_log_entry_model.dart';
import '../models/task_comment_model.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  const TaskRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TaskModel>> getMyTasks() async {
    final response = await _dio.get<List<dynamic>>('/tasks/me');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  Future<List<TaskModel>> getTasksAssignedByMe() async {
    final response = await _dio.get<List<dynamic>>('/tasks/assigned-by-me');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  Future<List<TaskModel>> getTeamTasks() async {
    final response = await _dio.get<List<dynamic>>('/tasks/team');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  Future<TaskModel> getTask(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/tasks/$id');
    return TaskModel.fromJson(response.data!);
  }

  Future<List<TaskAuditLogEntryModel>> getHistory(String id) async {
    final response = await _dio.get<List<dynamic>>('/tasks/$id/history');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TaskAuditLogEntryModel.fromJson)
        .toList();
  }

  Future<List<TaskCommentModel>> getComments(String id) async {
    final response = await _dio.get<List<dynamic>>('/tasks/$id/comments');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TaskCommentModel.fromJson)
        .toList();
  }

  Future<TaskCommentModel> addComment(String id, String body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tasks/$id/comments',
      data: {'body': body},
    );
    return TaskCommentModel.fromJson(response.data!);
  }

  Future<TaskModel> createTask({
    required String title,
    String? description,
    required String assigneeEmployeeId,
    String? priority,
    required String dueDate,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/tasks',
      data: {
        'title': title,
        'description': ?description,
        'assigneeEmployeeId': assigneeEmployeeId,
        'priority': ?priority,
        'dueDate': dueDate,
      },
    );
    return TaskModel.fromJson(response.data!);
  }

  Future<TaskModel> updateTask(
    String id, {
    String? title,
    String? description,
    String? assigneeEmployeeId,
    String? priority,
    String? dueDate,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/tasks/$id',
      data: {
        'title': ?title,
        'description': ?description,
        'assigneeEmployeeId': ?assigneeEmployeeId,
        'priority': ?priority,
        'dueDate': ?dueDate,
      },
    );
    return TaskModel.fromJson(response.data!);
  }

  Future<TaskModel> updateStatus(String id, String status) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/tasks/$id/status',
      data: {'status': status},
    );
    return TaskModel.fromJson(response.data!);
  }
}
