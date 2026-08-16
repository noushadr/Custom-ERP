class Team {
  const Team({
    required this.id,
    required this.name,
    required this.departmentId,
    this.departmentName,
    this.leadEmployeeId,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String departmentId;
  final String? departmentName;
  final String? leadEmployeeId;
  final bool isArchived;
}
