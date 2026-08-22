class Client {
  const Client({
    required this.id,
    required this.companyName,
    required this.industry,
    required this.website,
    required this.country,
    required this.address,
    required this.primaryContactName,
    required this.primaryContactEmail,
    required this.primaryContactPhone,
    required this.notes,
    required this.isArchived,
    required this.healthStatus,
    required this.healthFactors,
    required this.healthNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyName;
  final String? industry;
  final String? website;
  final String? country;
  final String? address;
  final String? primaryContactName;
  final String? primaryContactEmail;
  final String? primaryContactPhone;
  final String? notes;
  final bool isArchived;

  /// One of ClientHealthStatus's values.
  final String healthStatus;

  /// Zero or more of ClientHealthFactor's values.
  final List<String> healthFactors;
  final String? healthNotes;

  final DateTime createdAt;
  final DateTime updatedAt;
}
