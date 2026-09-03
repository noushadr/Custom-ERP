class PayrollDepartmentTotal {
  const PayrollDepartmentTotal({
    required this.departmentId,
    required this.departmentName,
    required this.totalNetPay,
    required this.itemCount,
  });

  final String? departmentId;

  /// "Unassigned" for an employee with no department, "Freelancers" for
  /// every freelancer line item grouped together.
  final String departmentName;
  final double totalNetPay;
  final int itemCount;
}
