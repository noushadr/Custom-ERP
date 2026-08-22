import 'package:dio/dio.dart';
import '../models/automation_execution_history_entry_model.dart';
import '../models/automation_model.dart';

class AutomationsRemoteDataSource {
  const AutomationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AutomationModel>> getAutomations() async {
    final response = await _dio.get<List<dynamic>>('/automations');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AutomationModel.fromJson)
        .toList();
  }

  Future<AutomationModel> updateAutomation(
    String type, {
    bool? isActive,
    int? daysBefore,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/automations/$type',
      data: {'isActive': ?isActive, 'daysBefore': ?daysBefore},
    );
    return AutomationModel.fromJson(response.data!);
  }

  Future<List<AutomationExecutionHistoryEntryModel>> getHistory({
    String? type,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/automations/history',
      queryParameters: {'type': ?type},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(AutomationExecutionHistoryEntryModel.fromJson)
        .toList();
  }

  Future<AutomationExecutionHistoryEntryModel> runNow(String type) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/automations/$type/run',
    );
    return AutomationExecutionHistoryEntryModel.fromJson(response.data!);
  }
}
