import 'package:dio/dio.dart';
import '../models/employee_request_model.dart';

class RequestRemoteDataSource {
  const RequestRemoteDataSource(this._dio);

  final Dio _dio;

  Future<EmployeeRequestModel> submit({
    required String subject,
    required String description,
    String? type,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/requests',
      data: {
        'subject': subject,
        'description': description,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    return EmployeeRequestModel.fromJson(response.data!);
  }

  Future<EmployeeRequestModel> submitProfileChangeRequest(
    Map<String, dynamic> changes,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/requests/profile-changes',
      data: changes,
    );
    return EmployeeRequestModel.fromJson(response.data!);
  }

  Future<List<EmployeeRequestModel>> getMine() async {
    final response = await _dio.get<List<dynamic>>('/requests/mine');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeRequestModel.fromJson)
        .toList();
  }

  Future<List<EmployeeRequestModel>> getPendingManagerApproval() async {
    final response = await _dio.get<List<dynamic>>(
      '/requests/pending-manager-approval',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeRequestModel.fromJson)
        .toList();
  }

  Future<List<EmployeeRequestModel>> getPendingHrApproval() async {
    final response = await _dio.get<List<dynamic>>(
      '/requests/pending-hr-approval',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeRequestModel.fromJson)
        .toList();
  }

  Future<List<EmployeeRequestModel>> getHistory() async {
    final response = await _dio.get<List<dynamic>>('/requests/history');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeRequestModel.fromJson)
        .toList();
  }

  Future<List<EmployeeRequestModel>> getHistoryForMyTeam() async {
    final response = await _dio.get<List<dynamic>>('/requests/history/mine');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(EmployeeRequestModel.fromJson)
        .toList();
  }

  Future<EmployeeRequestModel> approveAsManager(String requestId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/requests/$requestId/manager-approve',
    );
    return EmployeeRequestModel.fromJson(response.data!);
  }

  Future<EmployeeRequestModel> rejectAsManager(
    String requestId, {
    String? reason,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/requests/$requestId/manager-reject',
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return EmployeeRequestModel.fromJson(response.data!);
  }

  Future<EmployeeRequestModel> approveAsHr(String requestId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/requests/$requestId/hr-approve',
    );
    return EmployeeRequestModel.fromJson(response.data!);
  }

  Future<EmployeeRequestModel> rejectAsHr(
    String requestId, {
    String? reason,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/requests/$requestId/hr-reject',
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return EmployeeRequestModel.fromJson(response.data!);
  }
}
