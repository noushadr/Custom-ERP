import 'package:dio/dio.dart';
import '../../domain/entities/payroll_line_item.dart';
import '../models/payroll_run_detail_model.dart';
import '../models/payroll_run_summary_model.dart';
import '../models/payslip_list_item_model.dart';

class PayrollRemoteDataSource {
  const PayrollRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PayrollRunSummaryModel>> getRuns() async {
    final response = await _dio.get<List<dynamic>>('/payroll/runs');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PayrollRunSummaryModel.fromJson)
        .toList();
  }

  Future<PayrollRunDetailModel> generateRun({
    required int month,
    required int year,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payroll/runs',
      data: {'month': month, 'year': year},
    );
    return PayrollRunDetailModel.fromJson(response.data!);
  }

  Future<PayrollRunDetailModel> getRun(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/payroll/runs/$id');
    return PayrollRunDetailModel.fromJson(response.data!);
  }

  Future<PayrollRunDetailModel> updateLineItem(
    String runId,
    String lineItemId, {
    double? baseSalary,
    int? absentDays,
    double? advanceSalary,
    List<PayrollEntry>? fines,
    List<PayrollEntry>? freelanceTasks,
    String? notes,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/payroll/runs/$runId/line-items/$lineItemId',
      data: {
        'baseSalary': ?baseSalary,
        'absentDays': ?absentDays,
        'advanceSalary': ?advanceSalary,
        if (fines != null)
          'fines': [
            for (final fine in fines)
              {'description': fine.description, 'amount': fine.amount},
          ],
        if (freelanceTasks != null)
          'freelanceTasks': [
            for (final task in freelanceTasks)
              {'description': task.description, 'amount': task.amount},
          ],
        'notes': ?notes,
      },
    );
    return PayrollRunDetailModel.fromJson(response.data!);
  }

  Future<PayrollRunDetailModel> syncRun(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payroll/runs/$id/sync',
    );
    return PayrollRunDetailModel.fromJson(response.data!);
  }

  Future<PayrollRunDetailModel> addFreelancerToRun(
    String runId, {
    required String freelancerId,
    required double baseSalary,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payroll/runs/$runId/freelancer-line-items',
      data: {
        'freelancerId': freelancerId,
        'baseSalary': baseSalary,
        'notes': ?notes,
      },
    );
    return PayrollRunDetailModel.fromJson(response.data!);
  }

  Future<PayrollRunSummaryModel> finalizeRun(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payroll/runs/$id/finalize',
    );
    return PayrollRunSummaryModel.fromJson(response.data!);
  }

  Future<PayrollRunSummaryModel> payRun(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payroll/runs/$id/pay',
    );
    return PayrollRunSummaryModel.fromJson(response.data!);
  }

  Future<List<int>> downloadPayslip(String runId, String lineItemId) async {
    final response = await _dio.get<List<int>>(
      '/payroll/runs/$runId/line-items/$lineItemId/payslip',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<List<PayslipListItemModel>> getEmployeePayslips(
    String employeeId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/payroll/employees/$employeeId/payslips',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PayslipListItemModel.fromJson)
        .toList();
  }

  Future<List<PayslipListItemModel>> getMyPayslips() async {
    final response = await _dio.get<List<dynamic>>('/payslips/mine');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PayslipListItemModel.fromJson)
        .toList();
  }

  Future<List<int>> downloadMyPayslip(String lineItemId) async {
    final response = await _dio.get<List<int>>(
      '/payslips/mine/$lineItemId',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}
