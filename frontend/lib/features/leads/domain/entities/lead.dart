class Lead {
  const Lead({
    required this.id,
    required this.leadDate,
    required this.fullName,
    required this.companyName,
    required this.leadSource,
    required this.phone,
    required this.email,
    required this.country,
    required this.remarks,
    required this.serviceInterested,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// ISO date (yyyy-MM-dd).
  final String leadDate;
  final String fullName;
  final String? companyName;

  /// How this lead came in (e.g. "Referral", "LinkedIn") — free text.
  final String? leadSource;
  final String? phone;
  final String? email;
  final String? country;
  final String? remarks;

  /// Free-text service label — not linked to the Service catalog.
  final String? serviceInterested;
  final bool isArchived;

  final DateTime createdAt;
  final DateTime updatedAt;
}
