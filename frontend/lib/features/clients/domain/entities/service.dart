class Service {
  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}
