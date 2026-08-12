class Asset {
  const Asset({
    required this.id,
    required this.name,
    this.category,
    this.serialNumber,
    required this.status,
    required this.assignedEmployeeId,
    this.assignedAt,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? category;
  final String? serialNumber;

  /// One of: 'available', 'assigned', 'repair', 'lost', 'retired'.
  final String status;
  final String? assignedEmployeeId;
  final DateTime? assignedAt;
  final String? notes;
  final DateTime createdAt;
}
