import '../../domain/entities/payroll_line_item.dart';

class PayrollLineItemModel extends PayrollLineItem {
  const PayrollLineItemModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    required super.employeePhotoUrl,
    required super.baseSalary,
    required super.bonuses,
    required super.allowances,
    required super.overtime,
    required super.deductions,
    required super.advances,
    required super.tax,
    required super.netPay,
    required super.notes,
  });

  factory PayrollLineItemModel.fromJson(Map<String, dynamic> json) =>
      PayrollLineItemModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        employeeName: json['employeeName'] as String,
        employeePhotoUrl: json['employeePhotoUrl'] as String?,
        baseSalary: (json['baseSalary'] as num).toDouble(),
        bonuses: (json['bonuses'] as num).toDouble(),
        allowances: (json['allowances'] as num).toDouble(),
        overtime: (json['overtime'] as num).toDouble(),
        deductions: (json['deductions'] as num).toDouble(),
        advances: (json['advances'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        netPay: (json['netPay'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}
