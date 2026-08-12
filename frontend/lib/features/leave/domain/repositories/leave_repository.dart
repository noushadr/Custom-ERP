import '../entities/leave_balance.dart';
import '../entities/leave_calendar_entry.dart';
import '../entities/leave_request.dart';
import '../entities/leave_type.dart';

class LeaveResetStatus {
  const LeaveResetStatus({required this.year, required this.isInitialized});

  final int year;
  final bool isInitialized;
}

abstract interface class LeaveRepository {
  /// Throws [LeaveException] on failure.
  Future<List<LeaveType>> getLeaveTypes({bool includeArchived = false});

  Future<LeaveType> createLeaveType({
    required String name,
    required double annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
  });

  Future<LeaveType> updateLeaveType(
    String id, {
    String? name,
    double? annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
    bool? isArchived,
  });

  Future<void> deleteLeaveType(String id);

  Future<LeaveRequest> submitLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  });

  Future<LeaveRequest> cancelLeaveRequest(String requestId);

  Future<List<LeaveRequest>> getMyLeaveRequests();

  /// Requests submitted by one of this viewer's direct reports, awaiting
  /// their approval.
  Future<List<LeaveRequest>> getPendingManagerApproval();

  /// Requires `leave.manage`.
  Future<List<LeaveRequest>> getPendingHrApproval();

  Future<LeaveRequest> approveAsManager(String requestId, {String? comment});

  Future<LeaveRequest> rejectAsManager(String requestId, {String? comment});

  /// Requires `leave.manage`.
  Future<LeaveRequest> approveAsHr(String requestId, {String? comment});

  /// Requires `leave.manage`.
  Future<LeaveRequest> rejectAsHr(String requestId, {String? comment});

  Future<List<LeaveBalance>> getMyBalances();

  Future<List<LeaveBalance>> getMyBalanceHistory();

  /// Requires `leave.manage`.
  Future<List<LeaveBalance>> getEmployeeBalances(String employeeId);

  /// Requires `leave.manage`.
  Future<LeaveBalance> adjustBalance(
    String employeeId, {
    required String leaveTypeId,
    required int year,
    required double deltaDays,
    required String reason,
  });

  /// Requires `leave.manage`.
  Future<LeaveResetStatus> getResetStatus();

  /// Requires `leave.manage`.
  Future<void> runAnnualReset();

  /// `scope` is `'team'` (the viewer + their direct reports) or `'company'`.
  Future<List<LeaveCalendarEntry>> getLeaveCalendar({
    required String scope,
    required int month,
    required int year,
  });
}
