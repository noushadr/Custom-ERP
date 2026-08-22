import 'package:dio/dio.dart';
import '../../domain/entities/automation.dart';
import '../../domain/entities/automation_execution_history_entry.dart';
import '../../domain/exceptions/automations_exception.dart';
import '../../domain/repositories/automations_repository.dart';
import '../datasources/automations_remote_data_source.dart';

class AutomationsRepositoryImpl implements AutomationsRepository {
  const AutomationsRepositoryImpl(this._remoteDataSource);

  final AutomationsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Automation>> getAutomations() =>
      _guard(() => _remoteDataSource.getAutomations());

  @override
  Future<Automation> updateAutomation(
    String type, {
    bool? isActive,
    int? daysBefore,
  }) => _guard(
    () => _remoteDataSource.updateAutomation(
      type,
      isActive: isActive,
      daysBefore: daysBefore,
    ),
  );

  @override
  Future<List<AutomationExecutionHistoryEntry>> getHistory({String? type}) =>
      _guard(() => _remoteDataSource.getHistory(type: type));

  @override
  Future<AutomationExecutionHistoryEntry> runNow(String type) =>
      _guard(() => _remoteDataSource.runNow(type));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AutomationsException(_mapError(error));
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
