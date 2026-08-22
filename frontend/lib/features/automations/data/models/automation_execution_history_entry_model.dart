import '../../domain/entities/automation_execution_history_entry.dart';

class AutomationExecutionHistoryEntryModel
    extends AutomationExecutionHistoryEntry {
  const AutomationExecutionHistoryEntryModel({
    required super.id,
    required super.type,
    required super.triggeredBy,
    required super.status,
    required super.itemsProcessed,
    required super.notificationsCreated,
    required super.errorMessage,
    required super.runAt,
  });

  factory AutomationExecutionHistoryEntryModel.fromJson(
    Map<String, dynamic> json,
  ) => AutomationExecutionHistoryEntryModel(
    id: json['id'] as String,
    type: json['type'] as String,
    triggeredBy: json['triggeredBy'] as String,
    status: json['status'] as String,
    itemsProcessed: json['itemsProcessed'] as int,
    notificationsCreated: json['notificationsCreated'] as int,
    errorMessage: json['errorMessage'] as String?,
    runAt: DateTime.parse(json['runAt'] as String),
  );
}
