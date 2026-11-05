import 'package:zera_erp/features/payroll/domain/entities/payroll_department_total.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_line_item.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_detail.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_status.dart';
import 'package:zera_erp/features/payroll/domain/entities/payroll_run_summary.dart';
import 'package:zera_erp/features/payroll/domain/entities/payslip_list_item.dart';
import 'package:zera_erp/features/payroll/domain/repositories/payroll_repository.dart';

PayslipListItem buildTestPayslipListItem({
  String runId = 'run-1',
  String lineItemId = 'item-1',
  int month = 8,
  int year = 2026,
  double netPay = 50000,
  DateTime? paidAt,
}) {
  return PayslipListItem(
    runId: runId,
    lineItemId: lineItemId,
    month: month,
    year: year,
    netPay: netPay,
    paidAt: paidAt ?? DateTime(2026, 9, 1),
  );
}

PayrollLineItem buildTestPayrollLineItem({
  String id = 'item-1',
  String? employeeId = 'employee-1',
  String? freelancerId,
  bool isFreelancer = false,
  String employeeName = 'Jane Doe',
  String? employeePhotoUrl,
  double baseSalary = 50000,
  int lateDays = 0,
  int lateDeductionDays = 0,
  double lateHours = 0,
  int absentDays = 0,
  double advanceSalary = 0,
  List<PayrollEntry> fines = const [],
  List<PayrollEntry> freelanceTasks = const [],
  String? notes,
}) {
  // Late deduction is always base / 30 per unpaid day, like the backend.
  final lateDeduction = (lateDeductionDays * baseSalary / 30).roundToDouble();
  final absentDeduction = (absentDays * baseSalary / 30).roundToDouble();
  final lateHoursDeduction = (lateHours * baseSalary / 30 / 8).roundToDouble();
  final finesTotal = fines.fold<double>(0, (sum, fine) => sum + fine.amount);
  final freelanceTotal = freelanceTasks.fold<double>(
    0,
    (sum, task) => sum + task.amount,
  );
  return PayrollLineItem(
    id: id,
    employeeId: employeeId,
    freelancerId: freelancerId,
    isFreelancer: isFreelancer,
    employeeName: employeeName,
    employeePhotoUrl: employeePhotoUrl,
    baseSalary: baseSalary,
    lateDays: lateDays,
    lateDeductionDays: lateDeductionDays,
    lateDeduction: lateDeduction,
    absentDays: absentDays,
    absentDeduction: absentDeduction,
    advanceSalary: advanceSalary,
    lateHours: lateHours,
    lateHoursDeduction: lateHoursDeduction,
    fines: fines,
    finesTotal: finesTotal,
    freelanceTasks: freelanceTasks,
    freelanceTotal: freelanceTotal,
    netPay:
        baseSalary -
        lateDeduction -
        lateHoursDeduction -
        absentDeduction -
        advanceSalary -
        finesTotal +
        freelanceTotal,
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
  FakePayrollRepository({
    List<PayrollRunSummary>? runs,
    this.runDetail,
    List<PayslipListItem>? myPayslips,
  }) : runs = runs ?? [buildTestPayrollRunSummary()],
       myPayslips = myPayslips ?? [buildTestPayslipListItem()];

  final List<PayrollRunSummary> runs;
  final PayrollRunDetail? runDetail;
  final List<PayslipListItem> myPayslips;

  String? lastDownloadedRunId;
  String? lastDownloadedLineItemId;
  String? lastDownloadedMyLineItemId;

  int? lastGeneratedMonth;
  int? lastGeneratedYear;

  String? lastUpdatedLineItemId;
  double? lastUpdatedBaseSalary;
  List<PayrollEntry>? lastUpdatedFines;
  int? lastUpdatedAbsentDays;
  double? lastUpdatedAdvance;
  List<PayrollEntry>? lastUpdatedFreelanceTasks;
  String? lastSyncedRunId;

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
    int? absentDays,
    double? advanceSalary,
    List<PayrollEntry>? fines,
    List<PayrollEntry>? freelanceTasks,
    String? notes,
  }) async {
    lastUpdatedLineItemId = lineItemId;
    lastUpdatedBaseSalary = baseSalary;
    lastUpdatedFines = fines;
    lastUpdatedAbsentDays = absentDays;
    lastUpdatedAdvance = advanceSalary;
    lastUpdatedFreelanceTasks = freelanceTasks;
    return runDetail ?? buildTestPayrollRunDetail(id: runId);
  }

  @override
  Future<PayrollRunDetail> syncRun(String id) async {
    lastSyncedRunId = id;
    return runDetail ?? buildTestPayrollRunDetail(id: id);
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
    return buildTestPayrollRunSummary(
      id: id,
      status: PayrollRunStatus.finalized,
    );
  }

  @override
  Future<PayrollRunSummary> payRun(String id) async {
    lastPaidRunId = id;
    return buildTestPayrollRunSummary(id: id, status: PayrollRunStatus.paid);
  }

  @override
  Future<List<int>> downloadPayslip(String runId, String lineItemId) async {
    lastDownloadedRunId = runId;
    lastDownloadedLineItemId = lineItemId;
    return [1, 2, 3];
  }

  @override
  Future<List<PayslipListItem>> getMyPayslips() async => myPayslips;

  @override
  Future<List<PayslipListItem>> getEmployeePayslips(String employeeId) async =>
      myPayslips;

  @override
  Future<List<int>> downloadMyPayslip(String lineItemId) async {
    lastDownloadedMyLineItemId = lineItemId;
    return [1, 2, 3];
  }
}
