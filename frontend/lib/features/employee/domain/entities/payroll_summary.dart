class PayrollSummary {
  const PayrollSummary({
    required this.totalMonthlyPayroll,
    required this.dailyPayroll,
    required this.activeEmployeeCount,
  });

  /// Sum of the current salary of every active employee.
  final double totalMonthlyPayroll;

  /// [totalMonthlyPayroll] spread evenly across the days in the current
  /// calendar month.
  final double dailyPayroll;

  final int activeEmployeeCount;
}
