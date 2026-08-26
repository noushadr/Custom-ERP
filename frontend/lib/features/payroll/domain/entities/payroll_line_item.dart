class PayrollLineItem {
  const PayrollLineItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeePhotoUrl,
    required this.baseSalary,
    required this.quantity,
    required this.perUnitRate,
    required this.allowances,
    required this.overtime,
    required this.reimbursement,
    required this.commissions,
    required this.deductions,
    required this.advances,
    required this.tax,
    required this.fines,
    required this.totalAbsent,
    required this.absentDeductionRs,
    required this.lateHours,
    required this.lateHoursDeductionRs,
    required this.lateDays,
    required this.lateDaysDeductionRs,
    required this.netPay,
    required this.notes,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhotoUrl;

  /// The salary snapshot for salaried employees, or `quantity *
  /// perUnitRate` for piece-rate employees — whichever this run's
  /// effective base pay actually is.
  final double baseSalary;

  /// Piece-rate units this run; `null` for salaried employees.
  final int? quantity;
  final double? perUnitRate;

  final double allowances;
  final double overtime;
  final double reimbursement;
  final double commissions;
  final double deductions;
  final double advances;
  final double tax;
  final double fines;

  /// Entered count of full absence days this month.
  final int totalAbsent;

  /// Computed by the backend: totalAbsent * (baseSalary / 30).
  final double absentDeductionRs;

  /// Entered count of cumulative late hours this month.
  final int lateHours;

  /// Computed by the backend: lateHours * (baseSalary / 30 / 8).
  final double lateHoursDeductionRs;

  /// Entered count of late-arrival days this month.
  final int lateDays;

  /// Computed by the backend: `floor(lateDays / 3)` unpaid days ×
  /// (baseSalary / 30).
  final double lateDaysDeductionRs;

  /// Computed by the backend: baseSalary + allowances + overtime +
  /// reimbursement + commissions - deductions - advances - tax - fines -
  /// absentDeductionRs - lateHoursDeductionRs - lateDaysDeductionRs.
  final double netPay;
  final String? notes;
}
