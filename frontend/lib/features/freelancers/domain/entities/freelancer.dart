class Freelancer {
  const Freelancer({
    required this.id,
    required this.fullName,
    required this.role,
    required this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;

  /// Free-text description of what they do (e.g. "Content Writer") — not
  /// linked to Employee Management's Department/designation.
  final String? role;
  final String? notes;
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;
}
