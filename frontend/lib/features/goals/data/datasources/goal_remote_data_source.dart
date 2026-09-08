import 'package:dio/dio.dart';
import '../models/goal_model.dart';

class GoalRemoteDataSource {
  const GoalRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<GoalModel>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/goals');
    return response.data!.cast<Map<String, dynamic>>().map(GoalModel.fromJson).toList();
  }

  Future<List<GoalModel>> getMine() async {
    final response = await _dio.get<List<dynamic>>('/goals/me');
    return response.data!.cast<Map<String, dynamic>>().map(GoalModel.fromJson).toList();
  }

  Future<List<GoalModel>> getTeam() async {
    final response = await _dio.get<List<dynamic>>('/goals/team');
    return response.data!.cast<Map<String, dynamic>>().map(GoalModel.fromJson).toList();
  }

  Future<GoalModel> createForEmployee({
    required String employeeId,
    required String title,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals',
      data: {
        'employeeId': employeeId,
        'title': title,
        'description': ?description,
      },
    );
    return GoalModel.fromJson(response.data!);
  }

  Future<GoalModel> createForMyDirectReport({
    required String employeeId,
    required String title,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals/team',
      data: {
        'employeeId': employeeId,
        'title': title,
        'description': ?description,
      },
    );
    return GoalModel.fromJson(response.data!);
  }

  Future<List<GoalModel>> bulkAssignToDepartment({
    required String departmentId,
    required String title,
    String? description,
  }) async {
    final response = await _dio.post<List<dynamic>>(
      '/goals/bulk-assign',
      data: {
        'departmentId': departmentId,
        'title': title,
        'description': ?description,
      },
    );
    return response.data!.cast<Map<String, dynamic>>().map(GoalModel.fromJson).toList();
  }

  Future<GoalModel> update(
    String goalId, {
    String? title,
    String? description,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/goals/$goalId',
      data: {'title': ?title, 'description': ?description},
    );
    return GoalModel.fromJson(response.data!);
  }

  Future<GoalModel> updateAsManager(
    String goalId, {
    String? title,
    String? description,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/goals/$goalId/team',
      data: {'title': ?title, 'description': ?description},
    );
    return GoalModel.fromJson(response.data!);
  }

  Future<void> delete(String goalId) => _dio.delete('/goals/$goalId');

  Future<void> deleteAsManager(String goalId) =>
      _dio.delete('/goals/$goalId/team');
}
