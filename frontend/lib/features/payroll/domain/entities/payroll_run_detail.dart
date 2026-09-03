import 'payroll_department_total.dart';
import 'payroll_line_item.dart';
import 'payroll_run_summary.dart';

class PayrollRunDetail extends PayrollRunSummary {
  const PayrollRunDetail({
    required super.id,
    required super.month,
    required super.year,
    required super.status,
    required super.employeeCount,
    required super.totalNetPay,
    required super.generatedByName,
    required super.finalizedByName,
    required super.finalizedAt,
    required super.paidByName,
    required super.paidAt,
    required super.createdAt,
    required this.lineItems,
    required this.departmentTotals,
  });

  final List<PayrollLineItem> lineItems;

  /// This run's totalNetPay broken down by department, sorted
  /// highest-total first.
  final List<PayrollDepartmentTotal> departmentTotals;
}
