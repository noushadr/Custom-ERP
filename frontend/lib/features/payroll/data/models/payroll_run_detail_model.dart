import '../../domain/entities/payroll_run_detail.dart';
import 'payroll_department_total_model.dart';
import 'payroll_line_item_model.dart';

class PayrollRunDetailModel extends PayrollRunDetail {
  const PayrollRunDetailModel({
    required super.id,
    required super.month,
    required super.year,
    required super.status,
    required super.employeeCount,
    required super.totalNetPay,
    required super.generatedByName,
    required super.finalizedByName,
    required super.finalizedAt,
    required super.paidByName,
    required super.paidAt,
    required super.createdAt,
    required super.lineItems,
    required super.departmentTotals,
  });

  factory PayrollRunDetailModel.fromJson(Map<String, dynamic> json) =>
      PayrollRunDetailModel(
        id: json['id'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        status: json['status'] as String,
        employeeCount: json['employeeCount'] as int,
        totalNetPay: (json['totalNetPay'] as num).toDouble(),
        generatedByName: json['generatedByName'] as String,
        finalizedByName: json['finalizedByName'] as String?,
        finalizedAt: json['finalizedAt'] == null
            ? null
            : DateTime.parse(json['finalizedAt'] as String),
        paidByName: json['paidByName'] as String?,
        paidAt: json['paidAt'] == null
            ? null
            : DateTime.parse(json['paidAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lineItems: (json['lineItems'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(PayrollLineItemModel.fromJson)
            .toList(),
        departmentTotals: (json['departmentTotals'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(PayrollDepartmentTotalModel.fromJson)
            .toList(),
      );
}
