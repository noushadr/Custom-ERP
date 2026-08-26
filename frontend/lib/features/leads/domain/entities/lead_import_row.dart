/// One parsed row ready to send to the bulk-import endpoint — the same
/// shape `createLead` sends for a single lead. Built and validated
/// entirely client-side (see `lead_import_page.dart`'s parser) before ever
/// reaching the repository, so the backend can trust every row here is
/// already well-formed.
class LeadImportRow {
  const LeadImportRow({
    required this.leadDate,
    required this.fullName,
    this.companyName,
    this.leadSource,
    this.phone,
    this.email,
    this.country,
    this.remarks,
    this.serviceInterested,
  });

  /// ISO date (yyyy-MM-dd).
  final String leadDate;
  final String fullName;
  final String? companyName;
  final String? leadSource;
  final String? phone;
  final String? email;
  final String? country;
  final String? remarks;
  final String? serviceInterested;
}
