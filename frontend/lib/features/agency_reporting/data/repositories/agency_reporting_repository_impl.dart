import 'package:dio/dio.dart';
import '../../domain/entities/agency_report.dart';
import '../../domain/exceptions/agency_reporting_exception.dart';
import '../../domain/repositories/agency_reporting_repository.dart';
import '../datasources/agency_reporting_remote_data_source.dart';

class AgencyReportingRepositoryImpl implements AgencyReportingRepository {
  const AgencyReportingRepositoryImpl(this._remoteDataSource);

  final AgencyReportingRemoteDataSource _remoteDataSource;

  @override
  Future<AgencyReport> getReport({String? from, String? to}) async {
    try {
      return await _remoteDataSource.getReport(from: from, to: to);
    } on DioException catch (error) {
      throw AgencyReportingException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 403) return "You don't have permission to view this.";
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
