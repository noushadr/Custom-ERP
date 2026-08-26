import 'package:dio/dio.dart';
import '../../domain/entities/lead_import_row.dart';
import '../models/lead_model.dart';

class LeadsRemoteDataSource {
  const LeadsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LeadModel>> getLeads() async {
    final response = await _dio.get<List<dynamic>>('/leads');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(LeadModel.fromJson)
        .toList();
  }

  Future<int> importLeads(List<LeadImportRow> rows) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leads/import',
      data: {
        'leads': [
          for (final row in rows)
            {
              'leadDate': row.leadDate,
              'fullName': row.fullName,
              'companyName': ?row.companyName,
              'leadSource': ?row.leadSource,
              'phone': ?row.phone,
              'email': ?row.email,
              'country': ?row.country,
              'remarks': ?row.remarks,
              'serviceInterested': ?row.serviceInterested,
            },
        ],
      },
    );
    return response.data!['created'] as int;
  }

  Future<LeadModel> createLead({
    required String leadDate,
    required String fullName,
    String? companyName,
    String? leadSource,
    String? phone,
    String? email,
    String? country,
    String? remarks,
    String? serviceInterested,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leads',
      data: {
        'leadDate': leadDate,
        'fullName': fullName,
        'companyName': ?companyName,
        'leadSource': ?leadSource,
        'phone': ?phone,
        'email': ?email,
        'country': ?country,
        'remarks': ?remarks,
        'serviceInterested': ?serviceInterested,
      },
    );
    return LeadModel.fromJson(response.data!);
  }

  Future<LeadModel> updateLead(
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
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/leads/$id',
      data: {
        'leadDate': ?leadDate,
        'fullName': ?fullName,
        'companyName': ?companyName,
        'leadSource': ?leadSource,
        'phone': ?phone,
        'email': ?email,
        'country': ?country,
        'remarks': ?remarks,
        'serviceInterested': ?serviceInterested,
      },
    );
    return LeadModel.fromJson(response.data!);
  }
}
