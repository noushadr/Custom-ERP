class DepartmentPayrollTotal {
  const DepartmentPayrollTotal({
    required this.departmentId,
    required this.departmentName,
    required this.totalMonthlyPayroll,
    required this.employeeCount,
  });

  final String? departmentId;
  final String departmentName;
  final double totalMonthlyPayroll;
  final int employeeCount;
}

class PayrollSummary {
  const PayrollSummary({
    required this.totalMonthlyPayroll,
    required this.dailyPayroll,
    required this.activeEmployeeCount,
    required this.departmentTotals,
  });

  /// Sum of the current salary of every active employee.
  final double totalMonthlyPayroll;

  /// [totalMonthlyPayroll] spread evenly across the days in the current
  /// calendar month.
  final double dailyPayroll;

  final int activeEmployeeCount;

  /// [totalMonthlyPayroll] broken down by department, highest total first.
  final List<DepartmentPayrollTotal> departmentTotals;
}
