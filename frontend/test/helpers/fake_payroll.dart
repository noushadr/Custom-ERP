import 'package:zera_erp/features/payroll/domain/entities/payroll_line_item.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_detail.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_status.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_summary.dart';
import 'package:zera_erp/features/payroll/domain/repositories/payroll_repository.dart';

PayrollLineItem buildTestPayrollLineItem({
  String id = 'item-1',
  String employeeId = 'employee-1',
  String employeeName = 'Jane Doe',
  String? employeePhotoUrl,
  double baseSalary = 50000,
  double allowances = 0,
  double overtime = 0,
  double deductions = 0,
  double advances = 0,
  double tax = 0,
  double fines = 0,
  int lateCount = 0,
  double? lateDeductionRs,
  String? notes,
}) {
  final resolvedLateDeductionRs = lateDeductionRs ?? 0;
  return PayrollLineItem(
    id: id,
    employeeId: employeeId,
    employeeName: employeeName,
    employeePhotoUrl: employeePhotoUrl,
    baseSalary: baseSalary,
    allowances: allowances,
    overtime: overtime,
    deductions: deductions,
    advances: advances,
    tax: tax,
    fines: fines,
    lateCount: lateCount,
    lateDeductionRs: resolvedLateDeductionRs,
    netPay:
        baseSalary +
        allowances +
        overtime -
        deductions -
        advances -
        tax -
        fines -
        resolvedLateDeductionRs,
    notes: notes,
  );
}

PayrollRunSummary buildTestPayrollRunSummary({
  String id = 'run-1',
  int month = 8,
  int year = 2026,
  String status = PayrollRunStatus.draft,
  int employeeCount = 1,
  double totalNetPay = 50000,
  String generatedByName = 'Noushad Ranani',
  String? finalizedByName,
  DateTime? finalizedAt,
  String? paidByName,
  DateTime? paidAt,
  DateTime? createdAt,
}) {
  return PayrollRunSummary(
    id: id,
    month: month,
    year: year,
    status: status,
    employeeCount: employeeCount,
    totalNetPay: totalNetPay,
    generatedByName: generatedByName,
    finalizedByName: finalizedByName,
    finalizedAt: finalizedAt,
    paidByName: paidByName,
    paidAt: paidAt,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
  );
}

PayrollRunDetail buildTestPayrollRunDetail({
  String id = 'run-1',
  int month = 8,
  int year = 2026,
  String status = PayrollRunStatus.draft,
  String generatedByName = 'Noushad Ranani',
  String? finalizedByName,
  DateTime? finalizedAt,
  String? paidByName,
  DateTime? paidAt,
  DateTime? createdAt,
  List<PayrollLineItem>? lineItems,
}) {
  final resolvedLineItems = lineItems ?? [buildTestPayrollLineItem()];
  return PayrollRunDetail(
    id: id,
    month: month,
    year: year,
    status: status,
    employeeCount: resolvedLineItems.length,
    totalNetPay: resolvedLineItems.fold(0, (sum, item) => sum + item.netPay),
    generatedByName: generatedByName,
    finalizedByName: finalizedByName,
    finalizedAt: finalizedAt,
    paidByName: paidByName,
    paidAt: paidAt,
    createdAt: createdAt ?? DateTime(2026, 8, 1),
    lineItems: resolvedLineItems,
  );
}

class FakePayrollRepository implements PayrollRepository {
  FakePayrollRepository({List<PayrollRunSummary>? runs, this.runDetail})
    : runs = runs ?? [buildTestPayrollRunSummary()];

  final List<PayrollRunSummary> runs;
  final PayrollRunDetail? runDetail;

  int? lastGeneratedMonth;
  int? lastGeneratedYear;

  String? lastUpdatedLineItemId;
  double? lastUpdatedFines;
  int? lastUpdatedLateCount;
  double? lastUpdatedDeductions;

  String? lastFinalizedRunId;
  String? lastPaidRunId;

  /// Incremented on every [getRuns] call — used to confirm an unauthorized
  /// viewer's page never even fetches the list.
  int getRunsCallCount = 0;

  @override
  Future<List<PayrollRunSummary>> getRuns() async {
    getRunsCallCount++;
    return runs;
  }

  @override
  Future<PayrollRunDetail> generateRun({
    required int month,
    required int year,
  }) async {
    lastGeneratedMonth = month;
    lastGeneratedYear = year;
    return runDetail ?? buildTestPayrollRunDetail(month: month, year: year);
  }

  @override
  Future<PayrollRunDetail> getRun(String id) async =>
      runDetail ?? buildTestPayrollRunDetail(id: id);

  @override
  Future<PayrollRunDetail> updateLineItem(
    String runId,
    String lineItemId, {
    double? allowances,
    double? overtime,
    double? deductions,
    double? advances,
    double? tax,
    double? fines,
    int? lateCount,
    String? notes,
  }) async {
    lastUpdatedLineItemId = lineItemId;
    lastUpdatedFines = fines;
    lastUpdatedLateCount = lateCount;
    lastUpdatedDeductions = deductions;
    return runDetail ?? buildTestPayrollRunDetail(id: runId);
  }

  @override
  Future<PayrollRunSummary> finalizeRun(String id) async {
    lastFinalizedRunId = id;
    return buildTestPayrollRunSummary(id: id, status: PayrollRunStatus.finalized);
  }

  @override
  Future<PayrollRunSummary> payRun(String id) async {
    lastPaidRunId = id;
    return buildTestPayrollRunSummary(id: id, status: PayrollRunStatus.paid);
  }
}
