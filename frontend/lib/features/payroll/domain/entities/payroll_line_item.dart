class PayrollLineItem {
  const PayrollLineItem({
    required this.id,
    required this.employeeId,
    required this.freelancerId,
    required this.isFreelancer,
    required this.employeeName,
    required this.employeePhotoUrl,
    required this.baseSalary,
    required this.quantity,
    required this.perUnitRate,
    required this.netPay,
    required this.notes,
  });

  final String id;
  final String? employeeId;
  final String? freelancerId;

  /// `true` when this line item is a freelancer's rather than an
  /// employee's — [baseSalary] is directly editable for a freelancer, but
  /// a read-only snapshot for an employee.
  final bool isFreelancer;
  final String employeeName;
  final String? employeePhotoUrl;

  /// The salary snapshot for salaried employees, `quantity *
  /// perUnitRate` for piece-rate employees, or a directly-entered monthly
  /// amount for a freelancer — whichever this run's effective base pay
  /// actually is.
  final double baseSalary;

  /// Piece-rate units this run; `null` for salaried employees.
  final int? quantity;
  final double? perUnitRate;

  /// What was actually paid — a plain, directly-entered figure (defaults
  /// to [baseSalary] when the line item is created), not computed from any
  /// deduction/addition breakdown.
  final double netPay;
  final String? notes;
}
