import '../entities/payroll_run_detail.dart';
import '../entities/payroll_run_summary.dart';

abstract interface class PayrollRepository {
  Future<List<PayrollRunSummary>> getRuns();

  Future<PayrollRunDetail> generateRun({required int month, required int year});

  Future<PayrollRunDetail> getRun(String id);

  Future<PayrollRunDetail> updateLineItem(
    String runId,
    String lineItemId, {
    double? baseSalary,
    int? quantity,
    double? perUnitRate,
    double? netPay,
    String? notes,
  });

  /// Adds one freelancer to a draft run, with this month's pay entered
  /// directly (freelancers have no salary history to snapshot from).
  Future<PayrollRunDetail> addFreelancerToRun(
    String runId, {
    required String freelancerId,
    required double baseSalary,
    String? notes,
  });

  Future<PayrollRunSummary> finalizeRun(String id);

  Future<PayrollRunSummary> payRun(String id);
}
