import 'package:dio/dio.dart';
import '../../domain/entities/goal.dart';
import '../../domain/exceptions/goal_exception.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_remote_data_source.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(this._remoteDataSource);

  final GoalRemoteDataSource _remoteDataSource;

  @override
  Future<List<Goal>> getAll() => _guard(() => _remoteDataSource.getAll());

  @override
  Future<List<Goal>> getMine() => _guard(() => _remoteDataSource.getMine());

  @override
  Future<List<Goal>> getTeam() => _guard(() => _remoteDataSource.getTeam());

  @override
  Future<Goal> createForEmployee({
    required String employeeId,
    required String title,
    String? description,
  }) => _guard(
    () => _remoteDataSource.createForEmployee(
      employeeId: employeeId,
      title: title,
      description: description,
    ),
  );

  @override
  Future<Goal> createForMyDirectReport({
    required String employeeId,
    required String title,
    String? description,
  }) => _guard(
    () => _remoteDataSource.createForMyDirectReport(
      employeeId: employeeId,
      title: title,
      description: description,
    ),
  );

  @override
  Future<List<Goal>> bulkAssignToDepartment({
    required String departmentId,
    required String title,
    String? description,
  }) => _guard(
    () => _remoteDataSource.bulkAssignToDepartment(
      departmentId: departmentId,
      title: title,
      description: description,
    ),
  );

  @override
  Future<Goal> update(String goalId, {String? title, String? description}) =>
      _guard(
        () => _remoteDataSource.update(
          goalId,
          title: title,
          description: description,
        ),
      );

  @override
  Future<Goal> updateAsManager(
    String goalId, {
    String? title,
    String? description,
  }) => _guard(
    () => _remoteDataSource.updateAsManager(
      goalId,
      title: title,
      description: description,
    ),
  );

  @override
  Future<void> delete(String goalId) =>
      _guard(() => _remoteDataSource.delete(goalId));

  @override
  Future<void> deleteAsManager(String goalId) =>
      _guard(() => _remoteDataSource.deleteAsManager(goalId));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw GoalException(_mapError(error));
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
    if (status == 404) return 'That goal could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
