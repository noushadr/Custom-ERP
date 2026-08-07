import '../../domain/entities/audit_log_entry.dart';

class AuditLogEntryModel extends AuditLogEntry {
  const AuditLogEntryModel({
    required super.id,
    super.employeeName,
    required super.actorName,
    required super.fieldLabel,
    required super.oldValue,
    required super.newValue,
    required super.createdAt,
  });

  factory AuditLogEntryModel.fromJson(Map<String, dynamic> json) =>
      AuditLogEntryModel(
        id: json['id'] as String,
        employeeName: json['employeeName'] as String?,
        actorName: json['actorName'] as String,
        fieldLabel: json['fieldLabel'] as String,
        oldValue: json['oldValue'] as String?,
        newValue: json['newValue'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
