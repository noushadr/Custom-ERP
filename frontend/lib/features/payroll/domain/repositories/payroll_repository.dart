import '../entities/payroll_run_detail.dart';
import '../entities/payroll_run_summary.dart';

abstract interface class PayrollRepository {
  Future<List<PayrollRunSummary>> getRuns();

  Future<PayrollRunDetail> generateRun({required int month, required int year});

  Future<PayrollRunDetail> getRun(String id);

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
  });

  Future<PayrollRunSummary> finalizeRun(String id);

  Future<PayrollRunSummary> payRun(String id);
}
