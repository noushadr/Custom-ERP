/// Raw values matching the backend's KnowledgeBaseVisibility enum — kept as
/// plain strings (not a Dart enum) so JSON round-trips without a mapping
/// layer, same convention as PerformanceReview.status elsewhere.
class KnowledgeBaseVisibility {
  static const everyone = 'everyone';
  static const roles = 'roles';
  static const departments = 'departments';
  static const rolesAndDepartments = 'roles_and_departments';
}
