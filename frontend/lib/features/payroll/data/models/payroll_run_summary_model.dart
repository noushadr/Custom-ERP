import '../../domain/entities/payroll_run_summary.dart';

class PayrollRunSummaryModel extends PayrollRunSummary {
  const PayrollRunSummaryModel({
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
  });

  factory PayrollRunSummaryModel.fromJson(Map<String, dynamic> json) =>
      PayrollRunSummaryModel(
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
      );
}
