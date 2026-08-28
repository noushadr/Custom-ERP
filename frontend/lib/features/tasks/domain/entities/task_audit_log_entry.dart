/// A single field-change history entry — mirrors the backend's
/// TaskAuditLog shape.
class TaskAuditLogEntry {
  const TaskAuditLogEntry({
    required this.id,
    required this.actorName,
    required this.fieldLabel,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
  });

  final String id;
  final String actorName;
  final String fieldLabel;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;
}
