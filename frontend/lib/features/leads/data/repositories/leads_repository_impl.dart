import 'package:dio/dio.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_import_row.dart';
import '../../domain/exceptions/lead_exception.dart';
import '../../domain/repositories/leads_repository.dart';
import '../datasources/leads_remote_data_source.dart';

class LeadsRepositoryImpl implements LeadsRepository {
  const LeadsRepositoryImpl(this._remoteDataSource);

  final LeadsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Lead>> getLeads() => _guard(() => _remoteDataSource.getLeads());

  @override
  Future<int> importLeads(List<LeadImportRow> rows) =>
      _guard(() => _remoteDataSource.importLeads(rows));

  @override
  Future<Lead> createLead({
    required String leadDate,
    required String fullName,
    String? companyName,
    String? leadSource,
    String? phone,
    String? email,
    String? country,
    String? remarks,
    String? serviceInterested,
  }) => _guard(
    () => _remoteDataSource.createLead(
      leadDate: leadDate,
      fullName: fullName,
      companyName: companyName,
      leadSource: leadSource,
      phone: phone,
      email: email,
      country: country,
      remarks: remarks,
      serviceInterested: serviceInterested,
    ),
  );

  @override
  Future<Lead> updateLead(
    String id, {
    String? leadDate,
    String? fullName,
    String? companyName,
    String? leadSource,
    String? phone,
    String? email,
    String? country,
    String? remarks,
    String? serviceInterested,
  }) => _guard(
    () => _remoteDataSource.updateLead(
      id,
      leadDate: leadDate,
      fullName: fullName,
      companyName: companyName,
      leadSource: leadSource,
      phone: phone,
      email: email,
      country: country,
      remarks: remarks,
      serviceInterested: serviceInterested,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw LeadException(_mapError(error));
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
    if (status == 403) return "You don't have permission to do that.";
    if (status == 404) return 'That could not be found.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
