import 'package:dio/dio.dart';
import '../../domain/entities/financial_record.dart';
import '../../domain/exceptions/financial_record_exception.dart';
import '../../domain/repositories/financial_reports_repository.dart';
import '../datasources/financial_reports_remote_data_source.dart';

class FinancialReportsRepositoryImpl implements FinancialReportsRepository {
  const FinancialReportsRepositoryImpl(this._remoteDataSource);

  final FinancialReportsRemoteDataSource _remoteDataSource;

  @override
  Future<List<FinancialRecord>> getRecords() =>
      _guard(() => _remoteDataSource.getRecords());

  @override
  Future<FinancialRecord> createRecord({
    required int year,
    required int month,
    required String revenueRs,
    required String revenueUsd,
    required String expenseRs,
    required String expenseUsd,
    required String fxRate,
  }) => _guard(
    () => _remoteDataSource.createRecord(
      year: year,
      month: month,
      revenueRs: revenueRs,
      revenueUsd: revenueUsd,
      expenseRs: expenseRs,
      expenseUsd: expenseUsd,
      fxRate: fxRate,
    ),
  );

  @override
  Future<FinancialRecord> updateRecord(
    String id, {
    int? year,
    int? month,
    String? revenueRs,
    String? revenueUsd,
    String? expenseRs,
    String? expenseUsd,
    String? fxRate,
  }) => _guard(
    () => _remoteDataSource.updateRecord(
      id,
      year: year,
      month: month,
      revenueRs: revenueRs,
      revenueUsd: revenueUsd,
      expenseRs: expenseRs,
      expenseUsd: expenseUsd,
      fxRate: fxRate,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw FinancialRecordException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 409) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'A financial record for that month already exists.';
    }
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
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
