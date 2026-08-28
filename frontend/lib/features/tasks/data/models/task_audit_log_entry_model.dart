import '../../domain/entities/task_audit_log_entry.dart';

class TaskAuditLogEntryModel extends TaskAuditLogEntry {
  const TaskAuditLogEntryModel({
    required super.id,
    required super.actorName,
    required super.fieldLabel,
    required super.oldValue,
    required super.newValue,
    required super.createdAt,
  });

  factory TaskAuditLogEntryModel.fromJson(Map<String, dynamic> json) =>
      TaskAuditLogEntryModel(
        id: json['id'] as String,
        actorName: json['actorName'] as String,
        fieldLabel: json['fieldLabel'] as String,
        oldValue: json['oldValue'] as String?,
        newValue: json['newValue'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
