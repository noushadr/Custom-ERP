import '../../domain/entities/payroll_department_total.dart';

class PayrollDepartmentTotalModel extends PayrollDepartmentTotal {
  const PayrollDepartmentTotalModel({
    required super.departmentId,
    required super.departmentName,
    required super.totalNetPay,
    required super.itemCount,
  });

  factory PayrollDepartmentTotalModel.fromJson(Map<String, dynamic> json) =>
      PayrollDepartmentTotalModel(
        departmentId: json['departmentId'] as String?,
        departmentName: json['departmentName'] as String,
        totalNetPay: (json['totalNetPay'] as num).toDouble(),
        itemCount: json['itemCount'] as int,
      );
}
