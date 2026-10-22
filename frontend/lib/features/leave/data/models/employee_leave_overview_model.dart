import '../../../../shared/utils/photo_url.dart';
import '../../domain/entities/employee_leave_overview.dart';
import 'leave_balance_model.dart';

class EmployeeLeaveOverviewModel extends EmployeeLeaveOverview {
  const EmployeeLeaveOverviewModel({
    required super.employeeId,
    required super.employeeCode,
    required super.employeeName,
    super.departmentName,
    super.profilePhotoUrl,
    required super.balances,
    required super.totalAllocated,
    required super.totalUsed,
    required super.totalRemaining,
  });

  factory EmployeeLeaveOverviewModel.fromJson(Map<String, dynamic> json) =>
      EmployeeLeaveOverviewModel(
        employeeId: json['employeeId'] as String,
        employeeCode: json['employeeCode'] as String,
        employeeName: json['employeeName'] as String,
        departmentName: json['departmentName'] as String?,
        profilePhotoUrl: resolvePhotoUrl(json['profilePhotoUrl'] as String?),
        balances: (json['balances'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(LeaveBalanceModel.fromJson)
            .toList(),
        totalAllocated: (json['totalAllocated'] as num).toDouble(),
        totalUsed: (json['totalUsed'] as num).toDouble(),
        totalRemaining: (json['totalRemaining'] as num).toDouble(),
      );
}
