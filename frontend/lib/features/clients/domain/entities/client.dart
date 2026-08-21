class Client {
  const Client({
    required this.id,
    required this.companyName,
    required this.industry,
    required this.website,
    required this.address,
    required this.primaryContactName,
    required this.primaryContactEmail,
    required this.primaryContactPhone,
    required this.notes,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyName;
  final String? industry;
  final String? website;
  final String? address;
  final String? primaryContactName;
  final String? primaryContactEmail;
  final String? primaryContactPhone;
  final String? notes;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}
