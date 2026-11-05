/// One line with a reason and an amount: a fine, or a piece of freelance
/// work paid on top of the salary.
class PayrollEntry {
  const PayrollEntry({required this.description, required this.amount});

  final String description;
  final double amount;
}

class PayrollLineItem {
  const PayrollLineItem({
    required this.id,
    required this.employeeId,
    required this.freelancerId,
    required this.isFreelancer,
    required this.employeeName,
    required this.employeePhotoUrl,
    required this.baseSalary,
    required this.lateDays,
    required this.lateDeductionDays,
    required this.lateDeduction,
    required this.absentDays,
    required this.absentDeduction,
    required this.advanceSalary,
    required this.lateHours,
    required this.lateHoursDeduction,
    required this.fines,
    required this.finesTotal,
    required this.freelanceTasks,
    required this.freelanceTotal,
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

  /// The salary snapshot, or a directly-entered amount for a freelancer.
  final double baseSalary;

  /// Late arrivals counted from attendance for the month.
  final int lateDays;

  /// Unpaid days those lates earn.
  final int lateDeductionDays;

  /// [lateDeductionDays] at base salary / 30 — always 30 calendar days.
  final double lateDeduction;

  /// Unpaid absent days entered by HR.
  final int absentDays;

  /// [absentDays] at base salary / 30 each.
  final double absentDeduction;

  /// Advance salary already paid out, taken off this run.
  final double advanceSalary;

  /// Hours cut counted from attendance (2 = two hours).
  final double lateHours;

  /// [lateHours] at base salary / 30 / 8 per hour.
  final double lateHoursDeduction;
  final List<PayrollEntry> fines;
  final double finesTotal;
  final List<PayrollEntry> freelanceTasks;
  final double freelanceTotal;

  /// `baseSalary - lateDeduction - lateHoursDeduction - absentDeduction -
  /// advanceSalary - finesTotal + freelanceTotal` — computed
  /// server-side.
  final double netPay;
  final String? notes;
}
