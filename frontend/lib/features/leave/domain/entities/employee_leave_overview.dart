import 'leave_balance.dart';

/// One row of the HR/Admin "all employees' leave" table: an active
/// employee's current-year balance for every leave type, plus the same
/// figures summed across types.
class EmployeeLeaveOverview {
  const EmployeeLeaveOverview({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    this.departmentName,
    this.profilePhotoUrl,
    required this.balances,
    required this.totalAllocated,
    required this.totalUsed,
    required this.totalRemaining,
  });

  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String? departmentName;
  final String? profilePhotoUrl;
  final List<LeaveBalance> balances;
  final double totalAllocated;
  final double totalUsed;
  final double totalRemaining;
}
