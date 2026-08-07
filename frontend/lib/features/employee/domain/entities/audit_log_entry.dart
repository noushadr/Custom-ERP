class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    this.employeeName,
    required this.actorName,
    required this.fieldLabel,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
  });

  final String id;
  /// Only populated on the combined company-wide feed.
  final String? employeeName;
  final String actorName;
  final String fieldLabel;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;
}

extension AuditLogEntryDescription on AuditLogEntry {
  /// A human-readable summary of the change, e.g. "Old → New", or just the
  /// one side that's set for additive/removal-only changes (uploads, deletes).
  String get describeChange {
    final hasOld = oldValue != null && oldValue!.isNotEmpty;
    final hasNew = newValue != null && newValue!.isNotEmpty;
    if (hasOld && hasNew) return '$oldValue → $newValue';
    if (hasNew) return newValue!;
    if (hasOld) return oldValue!;
    return 'No details recorded.';
  }
}
