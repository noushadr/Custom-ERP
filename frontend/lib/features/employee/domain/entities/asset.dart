class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.status,
    required this.assignedEmployeeId,
    this.assignedAt,
    this.value,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// One of: 'available', 'assigned', 'repair', 'lost', 'retired'.
  final String status;
  final String? assignedEmployeeId;
  final DateTime? assignedAt;

  /// The asset's value in PKR, if known.
  final double? value;
  final DateTime createdAt;
}
