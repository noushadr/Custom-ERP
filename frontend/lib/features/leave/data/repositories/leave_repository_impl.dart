import 'package:dio/dio.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_calendar_entry.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/exceptions/leave_exception.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  const LeaveRepositoryImpl(this._remoteDataSource);

  final LeaveRemoteDataSource _remoteDataSource;

  @override
  Future<List<LeaveType>> getLeaveTypes({bool includeArchived = false}) =>
      _guard(
        () => _remoteDataSource.getLeaveTypes(includeArchived: includeArchived),
      );

  @override
  Future<LeaveType> createLeaveType({
    required String name,
    required double annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
  }) => _guard(
    () => _remoteDataSource.createLeaveType(
      name: name,
      annualAllowanceDays: annualAllowanceDays,
      carryForwardLimitDays: carryForwardLimitDays,
      colorHex: colorHex,
    ),
  );

  @override
  Future<LeaveType> updateLeaveType(
    String id, {
    String? name,
    double? annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
    bool? isArchived,
  }) => _guard(
    () => _remoteDataSource.updateLeaveType(
      id,
      name: name,
      annualAllowanceDays: annualAllowanceDays,
      carryForwardLimitDays: carryForwardLimitDays,
      colorHex: colorHex,
      isArchived: isArchived,
    ),
  );

  @override
  Future<void> deleteLeaveType(String id) =>
      _guard(() => _remoteDataSource.deleteLeaveType(id));

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  }) => _guard(
    () => _remoteDataSource.submitLeaveRequest(
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    ),
  );

  @override
  Future<LeaveRequest> cancelLeaveRequest(String requestId) =>
      _guard(() => _remoteDataSource.cancelLeaveRequest(requestId));

  @override
  Future<List<LeaveRequest>> getMyLeaveRequests() =>
      _guard(() => _remoteDataSource.getMyLeaveRequests());

  @override
  Future<List<LeaveRequest>> getPendingManagerApproval() =>
      _guard(() => _remoteDataSource.getPendingManagerApproval());

  @override
  Future<List<LeaveRequest>> getPendingHrApproval() =>
      _guard(() => _remoteDataSource.getPendingHrApproval());

  @override
  Future<LeaveRequest> approveAsManager(String requestId, {String? comment}) =>
      _guard(
        () => _remoteDataSource.approveAsManager(requestId, comment: comment),
      );

  @override
  Future<LeaveRequest> rejectAsManager(String requestId, {String? comment}) =>
      _guard(
        () => _remoteDataSource.rejectAsManager(requestId, comment: comment),
      );

  @override
  Future<LeaveRequest> approveAsHr(String requestId, {String? comment}) =>
      _guard(() => _remoteDataSource.approveAsHr(requestId, comment: comment));

  @override
  Future<LeaveRequest> rejectAsHr(String requestId, {String? comment}) =>
      _guard(() => _remoteDataSource.rejectAsHr(requestId, comment: comment));

  @override
  Future<List<LeaveBalance>> getMyBalances() =>
      _guard(() => _remoteDataSource.getMyBalances());

  @override
  Future<List<LeaveBalance>> getMyBalanceHistory() =>
      _guard(() => _remoteDataSource.getMyBalanceHistory());

  @override
  Future<List<LeaveBalance>> getEmployeeBalances(String employeeId) =>
      _guard(() => _remoteDataSource.getEmployeeBalances(employeeId));

  @override
  Future<LeaveBalance> adjustBalance(
    String employeeId, {
    required String leaveTypeId,
    required int year,
    required double deltaDays,
    required String reason,
  }) => _guard(
    () => _remoteDataSource.adjustBalance(
      employeeId,
      leaveTypeId: leaveTypeId,
      year: year,
      deltaDays: deltaDays,
      reason: reason,
    ),
  );

  @override
  Future<LeaveResetStatus> getResetStatus() =>
      _guard(() => _remoteDataSource.getResetStatus());

  @override
  Future<void> runAnnualReset() =>
      _guard(() => _remoteDataSource.runAnnualReset());

  @override
  Future<List<LeaveCalendarEntry>> getLeaveCalendar({
    required String scope,
    required int month,
    required int year,
  }) => _guard(
    () => _remoteDataSource.getLeaveCalendar(
      scope: scope,
      month: month,
      year: year,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw LeaveException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
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
