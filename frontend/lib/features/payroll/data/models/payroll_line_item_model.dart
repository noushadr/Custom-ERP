import '../../../../shared/utils/photo_url.dart';
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
    required super.lateDays,
    required super.lateDeductionDays,
    required super.lateDeduction,
    required super.absentDays,
    required super.absentDeduction,
    required super.advanceSalary,
    required super.lateHours,
    required super.lateHoursDeduction,
    required super.fines,
    required super.finesTotal,
    required super.freelanceTasks,
    required super.freelanceTotal,
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
        employeePhotoUrl: resolvePhotoUrl(json['employeePhotoUrl'] as String?),
        baseSalary: (json['baseSalary'] as num).toDouble(),
        lateDays: (json['lateDays'] as num).toInt(),
        lateDeductionDays: (json['lateDeductionDays'] as num).toInt(),
        lateDeduction: (json['lateDeduction'] as num).toDouble(),
        absentDays: (json['absentDays'] as num).toInt(),
        absentDeduction: (json['absentDeduction'] as num).toDouble(),
        advanceSalary: (json['advanceSalary'] as num).toDouble(),
        lateHours: (json['lateHours'] as num).toDouble(),
        lateHoursDeduction: (json['lateHoursDeduction'] as num).toDouble(),
        fines: _entries(json['fines']),
        finesTotal: (json['finesTotal'] as num).toDouble(),
        freelanceTasks: _entries(json['freelanceTasks']),
        freelanceTotal: (json['freelanceTotal'] as num).toDouble(),
        netPay: (json['netPay'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}

List<PayrollEntry> _entries(dynamic raw) => [
  for (final entry in raw as List<dynamic>)
    PayrollEntry(
      description: (entry as Map<String, dynamic>)['description'] as String,
      amount: (entry['amount'] as num).toDouble(),
    ),
];
