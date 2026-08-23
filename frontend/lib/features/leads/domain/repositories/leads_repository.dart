import '../entities/lead.dart';

abstract interface class LeadsRepository {
  Future<List<Lead>> getLeads({bool includeArchived = false});
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
  });
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
    bool? isArchived,
  });
}
