class Department {
  const Department({
    required this.id,
    required this.name,
    this.description,
    this.headEmployeeId,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? headEmployeeId;
  final bool isArchived;
}
