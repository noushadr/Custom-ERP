import 'package:dio/dio.dart';
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
