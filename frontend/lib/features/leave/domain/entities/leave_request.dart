class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.requesterName,
    this.requesterPhotoUrl,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.reason,
    required this.status,
    this.managerDecisionAt,
    this.managerDecisionByName,
    this.managerComment,
    this.hrDecisionAt,
    this.hrDecisionByName,
    this.hrComment,
    this.cancelledAt,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String requesterName;
  final String? requesterPhotoUrl;
  final String leaveTypeId;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final double numberOfDays;
  final String reason;

  /// One of: `submitted`, `manager_approved`, `approved`, `rejected`, `cancelled`.
  final String status;
  final DateTime? managerDecisionAt;
  final String? managerDecisionByName;
  final String? managerComment;
  final DateTime? hrDecisionAt;
  final String? hrDecisionByName;
  final String? hrComment;
  final DateTime? cancelledAt;
  final DateTime createdAt;
}
