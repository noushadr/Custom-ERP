import 'package:dio/dio.dart';
import '../../domain/repositories/leave_repository.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_calendar_entry_model.dart';
import '../models/leave_request_model.dart';
import '../models/leave_type_model.dart';

class LeaveRemoteDataSource {
  const LeaveRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LeaveTypeModel>> getLeaveTypes({
    bool includeArchived = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/types',
      queryParameters: {'includeArchived': includeArchived.toString()},
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveTypeModel.fromJson)
        .toList();
  }

  Future<LeaveTypeModel> createLeaveType({
    required String name,
    required double annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leave/types',
      data: {
        'name': name,
        'annualAllowanceDays': annualAllowanceDays,
        'carryForwardLimitDays': ?carryForwardLimitDays,
        'colorHex': ?colorHex,
      },
    );
    return LeaveTypeModel.fromJson(response.data!);
  }

  Future<LeaveTypeModel> updateLeaveType(
    String id, {
    String? name,
    double? annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
    bool? isArchived,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/types/$id',
      data: {
        'name': ?name,
        'annualAllowanceDays': ?annualAllowanceDays,
        'carryForwardLimitDays': ?carryForwardLimitDays,
        'colorHex': ?colorHex,
        'isArchived': ?isArchived,
      },
    );
    return LeaveTypeModel.fromJson(response.data!);
  }

  Future<void> deleteLeaveType(String id) async {
    await _dio.delete<void>('/leave/types/$id');
  }

  Future<LeaveRequestModel> submitLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leave/requests',
      data: {
        'leaveTypeId': leaveTypeId,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
      },
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<LeaveRequestModel> cancelLeaveRequest(String requestId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$requestId/cancel',
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<List<LeaveRequestModel>> getMyLeaveRequests() async {
    final response = await _dio.get<List<dynamic>>('/leave/requests/mine');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveRequestModel.fromJson)
        .toList();
  }

  Future<List<LeaveRequestModel>> getPendingManagerApproval() async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/requests/pending-manager-approval',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveRequestModel.fromJson)
        .toList();
  }

  Future<List<LeaveRequestModel>> getPendingHrApproval() async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/requests/pending-hr-approval',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveRequestModel.fromJson)
        .toList();
  }

  Future<LeaveRequestModel> approveAsManager(
    String requestId, {
    String? comment,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$requestId/manager-approve',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<LeaveRequestModel> rejectAsManager(
    String requestId, {
    String? comment,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$requestId/manager-reject',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<LeaveRequestModel> approveAsHr(
    String requestId, {
    String? comment,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$requestId/hr-approve',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<LeaveRequestModel> rejectAsHr(
    String requestId, {
    String? comment,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leave/requests/$requestId/hr-reject',
      data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
    );
    return LeaveRequestModel.fromJson(response.data!);
  }

  Future<List<LeaveBalanceModel>> getMyBalances() async {
    final response = await _dio.get<List<dynamic>>('/leave/balances/mine');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveBalanceModel.fromJson)
        .toList();
  }

  Future<List<LeaveBalanceModel>> getMyBalanceHistory() async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/balances/mine/history',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveBalanceModel.fromJson)
        .toList();
  }

  Future<List<LeaveBalanceModel>> getEmployeeBalances(
    String employeeId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/balances/$employeeId',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveBalanceModel.fromJson)
        .toList();
  }

  Future<LeaveBalanceModel> adjustBalance(
    String employeeId, {
    required String leaveTypeId,
    required int year,
    required double deltaDays,
    required String reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leave/balances/$employeeId/adjust',
      data: {
        'leaveTypeId': leaveTypeId,
        'year': year,
        'deltaDays': deltaDays,
        'reason': reason,
      },
    );
    return LeaveBalanceModel.fromJson(response.data!);
  }

  Future<LeaveResetStatus> getResetStatus() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leave/reset-status',
    );
    return LeaveResetStatus(
      year: response.data!['year'] as int,
      isInitialized: response.data!['isInitialized'] as bool,
    );
  }

  Future<void> runAnnualReset() async {
    await _dio.post<void>('/leave/reset');
  }

  Future<List<LeaveCalendarEntryModel>> getLeaveCalendar({
    required String scope,
    required int month,
    required int year,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/leave/calendar',
      queryParameters: {
        'scope': scope,
        'month': month.toString(),
        'year': year.toString(),
      },
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeaveCalendarEntryModel.fromJson)
        .toList();
  }
}
