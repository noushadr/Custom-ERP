/// A project's assigned-employee entry — a lightweight reference, not the
/// full Employee entity.
class ProjectEmployeeRef {
  const ProjectEmployeeRef({
    required this.id,
    required this.fullName,
    required this.photoUrl,
  });

  final String id;
  final String fullName;
  final String? photoUrl;
}

class ProjectDepartmentRef {
  const ProjectDepartmentRef({required this.id, required this.name});

  final String id;
  final String name;
}

class ProjectServiceRef {
  const ProjectServiceRef({required this.id, required this.name});

  final String id;
  final String name;
}
