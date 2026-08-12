import 'package:zera_erp/features/leave/domain/entities/leave_balance.dart';
import 'package:zera_erp/features/leave/domain/entities/leave_calendar_entry.dart';
import 'package:zera_erp/features/leave/domain/entities/leave_request.dart';
import 'package:zera_erp/features/leave/domain/entities/leave_type.dart';
import 'package:zera_erp/features/leave/domain/repositories/leave_repository.dart';

LeaveCalendarEntry buildTestLeaveCalendarEntry({
  String employeeId = 'employee-1',
  String employeeName = 'Jane Doe',
  String leaveTypeId = 'leave-type-1',
  String leaveTypeName = 'Annual Leave',
  String? colorHex = '#00D5EE',
  String startDate = '2026-03-02',
  String endDate = '2026-03-06',
  bool isPending = false,
}) {
  return LeaveCalendarEntry(
    employeeId: employeeId,
    employeeName: employeeName,
    leaveTypeId: leaveTypeId,
    leaveTypeName: leaveTypeName,
    colorHex: colorHex,
    startDate: startDate,
    endDate: endDate,
    isPending: isPending,
  );
}

LeaveType buildTestLeaveType({
  String id = 'leave-type-1',
  String name = 'Annual Leave',
  double annualAllowanceDays = 20,
  double? carryForwardLimitDays,
  String? colorHex = '#00D5EE',
  bool isArchived = false,
}) {
  return LeaveType(
    id: id,
    name: name,
    annualAllowanceDays: annualAllowanceDays,
    carryForwardLimitDays: carryForwardLimitDays,
    colorHex: colorHex,
    isArchived: isArchived,
  );
}

LeaveBalance buildTestLeaveBalance({
  String leaveTypeId = 'leave-type-1',
  String leaveTypeName = 'Annual Leave',
  String? colorHex = '#00D5EE',
  int year = 2026,
  double allocated = 20,
  double used = 0,
  double remaining = 20,
}) {
  return LeaveBalance(
    leaveTypeId: leaveTypeId,
    leaveTypeName: leaveTypeName,
    colorHex: colorHex,
    year: year,
    allocated: allocated,
    used: used,
    remaining: remaining,
  );
}

LeaveRequest buildTestLeaveRequest({
  String id = 'leave-request-1',
  String employeeId = 'employee-1',
  String requesterName = 'Jane Doe',
  String leaveTypeId = 'leave-type-1',
  String leaveTypeName = 'Annual Leave',
  String startDate = '2026-03-02',
  String endDate = '2026-03-06',
  double numberOfDays = 5,
  String reason = 'Family trip',
  String status = 'submitted',
  String? managerDecisionByName,
  DateTime? managerDecisionAt,
  DateTime? hrDecisionAt,
}) {
  return LeaveRequest(
    id: id,
    employeeId: employeeId,
    requesterName: requesterName,
    leaveTypeId: leaveTypeId,
    leaveTypeName: leaveTypeName,
    startDate: startDate,
    endDate: endDate,
    numberOfDays: numberOfDays,
    reason: reason,
    status: status,
    managerDecisionByName: managerDecisionByName,
    managerDecisionAt: managerDecisionAt,
    hrDecisionAt: hrDecisionAt,
    createdAt: DateTime(2026, 1, 1),
  );
}

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository({
    this.leaveTypes = const [],
    this.myBalances = const [],
    this.myRequests = const [],
    this.pendingManagerApproval = const [],
    this.pendingHrApproval = const [],
    this.submitError,
    this.decisionError,
    this.resetStatus = const LeaveResetStatus(year: 2026, isInitialized: true),
    this.calendarEntries = const [],
  });

  final List<LeaveType> leaveTypes;
  final List<LeaveBalance> myBalances;
  final List<LeaveRequest> myRequests;
  final List<LeaveRequest> pendingManagerApproval;
  final List<LeaveRequest> pendingHrApproval;
  final Object? submitError;
  final Object? decisionError;
  final LeaveResetStatus resetStatus;
  final List<LeaveCalendarEntry> calendarEntries;

  String? lastCalendarScope;

  String? lastSubmittedLeaveTypeId;
  String? lastCancelledRequestId;
  String? lastDecidedRequestId;
  bool? lastDecisionApproved;
  String? lastDecisionComment;
  bool resetTriggered = false;

  @override
  Future<List<LeaveType>> getLeaveTypes({bool includeArchived = false}) async =>
      leaveTypes;

  @override
  Future<LeaveType> createLeaveType({
    required String name,
    required double annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
  }) async => buildTestLeaveType(
    name: name,
    annualAllowanceDays: annualAllowanceDays,
    carryForwardLimitDays: carryForwardLimitDays,
    colorHex: colorHex,
  );

  @override
  Future<LeaveType> updateLeaveType(
    String id, {
    String? name,
    double? annualAllowanceDays,
    double? carryForwardLimitDays,
    String? colorHex,
    bool? isArchived,
  }) async => buildTestLeaveType(
    id: id,
    name: name ?? 'Annual Leave',
    annualAllowanceDays: annualAllowanceDays ?? 20,
    carryForwardLimitDays: carryForwardLimitDays,
    colorHex: colorHex,
    isArchived: isArchived ?? false,
  );

  @override
  Future<void> deleteLeaveType(String id) async {}

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    lastSubmittedLeaveTypeId = leaveTypeId;
    if (submitError != null) throw submitError!;
    return buildTestLeaveRequest(
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );
  }

  @override
  Future<LeaveRequest> cancelLeaveRequest(String requestId) async {
    lastCancelledRequestId = requestId;
    if (decisionError != null) throw decisionError!;
    return buildTestLeaveRequest(id: requestId, status: 'cancelled');
  }

  @override
  Future<List<LeaveRequest>> getMyLeaveRequests() async => myRequests;

  @override
  Future<List<LeaveRequest>> getPendingManagerApproval() async =>
      pendingManagerApproval;

  @override
  Future<List<LeaveRequest>> getPendingHrApproval() async => pendingHrApproval;

  @override
  Future<LeaveRequest> approveAsManager(String requestId, {String? comment}) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = true;
    lastDecisionComment = comment;
    if (decisionError != null) throw decisionError!;
    return buildTestLeaveRequest(id: requestId, status: 'manager_approved');
  }

  @override
  Future<LeaveRequest> rejectAsManager(String requestId, {String? comment}) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = false;
    lastDecisionComment = comment;
    if (decisionError != null) throw decisionError!;
    return buildTestLeaveRequest(id: requestId, status: 'rejected');
  }

  @override
  Future<LeaveRequest> approveAsHr(String requestId, {String? comment}) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = true;
    lastDecisionComment = comment;
    if (decisionError != null) throw decisionError!;
    return buildTestLeaveRequest(id: requestId, status: 'approved');
  }

  @override
  Future<LeaveRequest> rejectAsHr(String requestId, {String? comment}) async {
    lastDecidedRequestId = requestId;
    lastDecisionApproved = false;
    lastDecisionComment = comment;
    if (decisionError != null) throw decisionError!;
    return buildTestLeaveRequest(id: requestId, status: 'rejected');
  }

  @override
  Future<List<LeaveBalance>> getMyBalances() async => myBalances;

  @override
  Future<List<LeaveBalance>> getMyBalanceHistory() async => myBalances;

  @override
  Future<List<LeaveBalance>> getEmployeeBalances(String employeeId) async =>
      myBalances;

  @override
  Future<LeaveBalance> adjustBalance(
    String employeeId, {
    required String leaveTypeId,
    required int year,
    required double deltaDays,
    required String reason,
  }) async => buildTestLeaveBalance(leaveTypeId: leaveTypeId, year: year);

  @override
  Future<LeaveResetStatus> getResetStatus() async => resetStatus;

  @override
  Future<void> runAnnualReset() async {
    resetTriggered = true;
  }

  @override
  Future<List<LeaveCalendarEntry>> getLeaveCalendar({
    required String scope,
    required int month,
    required int year,
  }) async {
    lastCalendarScope = scope;
    return calendarEntries;
  }
}
