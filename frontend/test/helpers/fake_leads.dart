import 'package:zera_erp/features/leads/domain/entities/lead.dart';
import 'package:zera_erp/features/leads/domain/entities/lead_import_row.dart';
import 'package:zera_erp/features/leads/domain/repositories/leads_repository.dart';

Lead buildTestLead({
  String id = 'lead-1',
  String leadDate = '2026-01-01',
  String fullName = 'Jane Prospect',
  String? companyName = 'Acme Inc',
  String? leadSource = 'Referral',
  String? phone,
  String? email,
  String? country,
  String? remarks,
  String? serviceInterested,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Lead(
    id: id,
    leadDate: leadDate,
    fullName: fullName,
    companyName: companyName,
    leadSource: leadSource,
    phone: phone,
    email: email,
    country: country,
    remarks: remarks,
    serviceInterested: serviceInterested,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

class FakeLeadsRepository implements LeadsRepository {
  FakeLeadsRepository({this.leads = const []});

  final List<Lead> leads;

  /// The `fullName` passed to the most recent [createLead] call.
  String? lastCreatedFullName;

  /// The id passed to the most recent [updateLead] call.
  String? lastUpdatedId;

  /// Incremented on every [getLeads] call — used to confirm a mutation
  /// actually invalidated and re-fetched the leads list provider.
  int getLeadsCallCount = 0;

  /// The rows passed to the most recent [importLeads] call.
  List<LeadImportRow>? lastImportedRows;

  /// Overrides the count [importLeads] returns; defaults to `rows.length`.
  int? importLeadsResultOverride;

  @override
  Future<List<Lead>> getLeads() async {
    getLeadsCallCount++;
    return leads;
  }

  @override
  Future<int> importLeads(List<LeadImportRow> rows) async {
    lastImportedRows = rows;
    return importLeadsResultOverride ?? rows.length;
  }

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
  }) async {
    lastCreatedFullName = fullName;
    return buildTestLead(
      leadDate: leadDate,
      fullName: fullName,
      companyName: companyName,
      leadSource: leadSource,
      phone: phone,
      email: email,
      country: country,
      remarks: remarks,
      serviceInterested: serviceInterested,
    );
  }

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
  }) async {
    lastUpdatedId = id;
    return buildTestLead(id: id);
  }
}
