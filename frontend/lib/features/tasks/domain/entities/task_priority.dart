/// Raw values matching the backend's TaskPriority enum — kept as plain
/// strings (not a Dart enum) so JSON round-trips without a mapping layer,
/// same convention as KnowledgeBaseVisibility/PerformanceReview.status.
class TaskPriority {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const urgent = 'urgent';

  static const values = [low, medium, high, urgent];
}
