class PayrollRunSummary {
  const PayrollRunSummary({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    required this.employeeCount,
    required this.totalNetPay,
    required this.generatedByName,
    required this.finalizedByName,
    required this.finalizedAt,
    required this.paidByName,
    required this.paidAt,
    required this.createdAt,
  });

  final String id;

  /// 1-12.
  final int month;
  final int year;

  /// One of PayrollRunStatus's values.
  final String status;
  final int employeeCount;
  final double totalNetPay;
  final String generatedByName;
  final String? finalizedByName;
  final DateTime? finalizedAt;
  final String? paidByName;
  final DateTime? paidAt;
  final DateTime createdAt;
}
