import '../../domain/entities/payroll_line_item.dart';

class PayrollLineItemModel extends PayrollLineItem {
  const PayrollLineItemModel({
    required super.id,
    required super.employeeId,
    required super.freelancerId,
    required super.isFreelancer,
    required super.employeeName,
    required super.employeePhotoUrl,
    required super.baseSalary,
    required super.quantity,
    required super.perUnitRate,
    required super.additions,
    required super.deductions,
    required super.netPay,
    required super.notes,
  });

  factory PayrollLineItemModel.fromJson(Map<String, dynamic> json) =>
      PayrollLineItemModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String?,
        freelancerId: json['freelancerId'] as String?,
        isFreelancer: json['isFreelancer'] as bool,
        employeeName: json['employeeName'] as String,
        employeePhotoUrl: json['employeePhotoUrl'] as String?,
        baseSalary: (json['baseSalary'] as num).toDouble(),
        quantity: json['quantity'] as int?,
        perUnitRate: (json['perUnitRate'] as num?)?.toDouble(),
        additions: (json['additions'] as num).toDouble(),
        deductions: (json['deductions'] as num).toDouble(),
        netPay: (json['netPay'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}
