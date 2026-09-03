import 'package:dio/dio.dart';
import '../../domain/entities/payroll_run_detail.dart';
import '../../domain/entities/payroll_run_summary.dart';
import '../../domain/exceptions/payroll_exception.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../datasources/payroll_remote_data_source.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  const PayrollRepositoryImpl(this._remoteDataSource);

  final PayrollRemoteDataSource _remoteDataSource;

  @override
  Future<List<PayrollRunSummary>> getRuns() =>
      _guard(() => _remoteDataSource.getRuns());

  @override
  Future<PayrollRunDetail> generateRun({
    required int month,
    required int year,
  }) => _guard(() => _remoteDataSource.generateRun(month: month, year: year));

  @override
  Future<PayrollRunDetail> getRun(String id) =>
      _guard(() => _remoteDataSource.getRun(id));

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
  }) => _guard(
    () => _remoteDataSource.updateLineItem(
      runId,
      lineItemId,
      baseSalary: baseSalary,
      quantity: quantity,
      perUnitRate: perUnitRate,
      additions: additions,
      deductions: deductions,
      notes: notes,
    ),
  );

  @override
  Future<PayrollRunDetail> addFreelancerToRun(
    String runId, {
    required String freelancerId,
    required double baseSalary,
    String? notes,
  }) => _guard(
    () => _remoteDataSource.addFreelancerToRun(
      runId,
      freelancerId: freelancerId,
      baseSalary: baseSalary,
      notes: notes,
    ),
  );

  @override
  Future<PayrollRunSummary> finalizeRun(String id) =>
      _guard(() => _remoteDataSource.finalizeRun(id));

  @override
  Future<PayrollRunSummary> payRun(String id) =>
      _guard(() => _remoteDataSource.payRun(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw PayrollException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
      return 'Invalid request.';
    }
    if (status == 409) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'That already exists.';
    }
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
