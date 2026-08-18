import '../../domain/entities/payroll_summary.dart';

class PayrollSummaryModel extends PayrollSummary {
  const PayrollSummaryModel({
    required super.totalMonthlyPayroll,
    required super.dailyPayroll,
    required super.activeEmployeeCount,
  });

  factory PayrollSummaryModel.fromJson(Map<String, dynamic> json) =>
      PayrollSummaryModel(
        totalMonthlyPayroll: (json['totalMonthlyPayroll'] as num).toDouble(),
        dailyPayroll: (json['dailyPayroll'] as num).toDouble(),
        activeEmployeeCount: json['activeEmployeeCount'] as int,
      );
}
