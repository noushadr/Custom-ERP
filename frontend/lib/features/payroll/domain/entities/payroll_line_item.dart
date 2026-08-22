class PayrollLineItem {
  const PayrollLineItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeePhotoUrl,
    required this.baseSalary,
    required this.bonuses,
    required this.allowances,
    required this.overtime,
    required this.deductions,
    required this.advances,
    required this.tax,
    required this.netPay,
    required this.notes,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhotoUrl;
  final double baseSalary;
  final double bonuses;
  final double allowances;
  final double overtime;
  final double deductions;
  final double advances;
  final double tax;

  /// Computed by the backend: baseSalary + bonuses + allowances + overtime
  /// - deductions - advances - tax.
  final double netPay;
  final String? notes;
}
