import 'package:dio/dio.dart';
import '../models/payroll_run_detail_model.dart';
import '../models/payroll_run_summary_model.dart';

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
    int? quantity,
    double? perUnitRate,
    double? additions,
    double? deductions,
    String? notes,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/payroll/runs/$runId/line-items/$lineItemId',
      data: {
        'baseSalary': ?baseSalary,
        'quantity': ?quantity,
        'perUnitRate': ?perUnitRate,
        'additions': ?additions,
        'deductions': ?deductions,
        'notes': ?notes,
      },
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
}
