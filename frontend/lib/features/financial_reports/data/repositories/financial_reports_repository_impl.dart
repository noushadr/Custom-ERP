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

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw FinancialRecordException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
