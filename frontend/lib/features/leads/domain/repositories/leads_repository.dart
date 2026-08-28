import '../entities/lead.dart';
import '../entities/lead_import_row.dart';

abstract interface class LeadsRepository {
  Future<List<Lead>> getLeads();

  /// Bulk-creates every row in one request; returns how many were created.
  Future<int> importLeads(List<LeadImportRow> rows);
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
  });
}
