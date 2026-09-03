import '../../domain/entities/payroll_summary.dart';

class DepartmentPayrollTotalModel extends DepartmentPayrollTotal {
  const DepartmentPayrollTotalModel({
    required super.departmentId,
    required super.departmentName,
    required super.totalMonthlyPayroll,
    required super.employeeCount,
  });

  factory DepartmentPayrollTotalModel.fromJson(Map<String, dynamic> json) =>
      DepartmentPayrollTotalModel(
        departmentId: json['departmentId'] as String?,
        departmentName: json['departmentName'] as String,
        totalMonthlyPayroll: (json['totalMonthlyPayroll'] as num).toDouble(),
        employeeCount: json['employeeCount'] as int,
      );
}

class PayrollSummaryModel extends PayrollSummary {
  const PayrollSummaryModel({
    required super.totalMonthlyPayroll,
    required super.dailyPayroll,
    required super.activeEmployeeCount,
    required super.departmentTotals,
  });

  factory PayrollSummaryModel.fromJson(Map<String, dynamic> json) =>
      PayrollSummaryModel(
        totalMonthlyPayroll: (json['totalMonthlyPayroll'] as num).toDouble(),
        dailyPayroll: (json['dailyPayroll'] as num).toDouble(),
        activeEmployeeCount: json['activeEmployeeCount'] as int,
        departmentTotals:
            (json['departmentTotals'] as List<dynamic>? ?? [])
                .map(
                  (e) => DepartmentPayrollTotalModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );
}
