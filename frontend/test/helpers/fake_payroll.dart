import 'package:zera_erp/features/payroll/domain/entities/payroll_department_total.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_line_item.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_detail.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_status.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_summary.dart';
import 'package:zera_erp/features/payroll/domain/repositories/payroll_repository.dart';

PayrollLineItem buildTestPayrollLineItem({
  String id = 'item-1',
  String? employeeId = 'employee-1',
  String? freelancerId,
  bool isFreelancer = false,
  String employeeName = 'Jane Doe',
  String? employeePhotoUrl,
  double baseSalary = 50000,
  int? quantity,
  double? perUnitRate,
  double additions = 0,
  double deductions = 0,
  String? notes,
}) {
  final effectiveBaseSalary =
      (quantity != null && quantity > 0 && perUnitRate != null)
      ? quantity * perUnitRate
      : baseSalary;
  return PayrollLineItem(
    id: id,
    employeeId: employeeId,
    freelancerId: freelancerId,
    isFreelancer: isFreelancer,
    employeeName: employeeName,
    employeePhotoUrl: employeePhotoUrl,
    baseSalary: effectiveBaseSalary,
    quantity: quantity,
    perUnitRate: perUnitRate,
    additions: additions,
    deductions: deductions,
    netPay: effectiveBaseSalary + additions - deductions,
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
  List<PayrollDepartmentTotal>? departmentTotals,
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
    departmentTotals: departmentTotals ?? const [],
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
  double? lastUpdatedBaseSalary;
  int? lastUpdatedQuantity;
  double? lastUpdatedPerUnitRate;
  double? lastUpdatedAdditions;
  double? lastUpdatedDeductions;

  String? lastFinalizedRunId;
  String? lastPaidRunId;

  String? lastAddedFreelancerRunId;
  String? lastAddedFreelancerId;
  double? lastAddedFreelancerBaseSalary;
  String? lastAddedFreelancerNotes;

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
    double? baseSalary,
    int? quantity,
    double? perUnitRate,
    double? additions,
    double? deductions,
    String? notes,
  }) async {
    lastUpdatedLineItemId = lineItemId;
    lastUpdatedBaseSalary = baseSalary;
    lastUpdatedQuantity = quantity;
    lastUpdatedPerUnitRate = perUnitRate;
    lastUpdatedAdditions = additions;
    lastUpdatedDeductions = deductions;
    return runDetail ?? buildTestPayrollRunDetail(id: runId);
  }

  @override
  Future<PayrollRunDetail> addFreelancerToRun(
    String runId, {
    required String freelancerId,
    required double baseSalary,
    String? notes,
  }) async {
    lastAddedFreelancerRunId = runId;
    lastAddedFreelancerId = freelancerId;
    lastAddedFreelancerBaseSalary = baseSalary;
    lastAddedFreelancerNotes = notes;
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
