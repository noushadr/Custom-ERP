class PayrollLineItem {
  const PayrollLineItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeePhotoUrl,
    required this.baseSalary,
    required this.allowances,
    required this.overtime,
    required this.deductions,
    required this.advances,
    required this.tax,
    required this.fines,
    required this.lateCount,
    required this.lateDeductionRs,
    required this.netPay,
    required this.notes,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhotoUrl;
  final double baseSalary;
  final double allowances;
  final double overtime;
  final double deductions;
  final double advances;
  final double tax;
  final double fines;

  /// Entered count of late arrivals this month.
  final int lateCount;

  /// Computed by the backend: `floor(lateCount / 3)` unpaid days ×
  /// (baseSalary / days in the run's month).
  final double lateDeductionRs;

  /// Computed by the backend: baseSalary + allowances + overtime -
  /// deductions - advances - tax - fines - lateDeductionRs.
  final double netPay;
  final String? notes;
}
