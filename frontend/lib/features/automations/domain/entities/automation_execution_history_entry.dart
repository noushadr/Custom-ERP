/// One immutable row per run of an automation (daily cron or a manual
/// "Run Now").
class AutomationExecutionHistoryEntry {
  const AutomationExecutionHistoryEntry({
    required this.id,
    required this.type,
    required this.triggeredBy,
    required this.status,
    required this.itemsProcessed,
    required this.notificationsCreated,
    required this.errorMessage,
    required this.runAt,
  });

  final String id;

  /// One of AutomationType's values.
  final String type;

  /// 'cron' | 'manual'.
  final String triggeredBy;

  /// 'success' | 'error'.
  final String status;
  final int itemsProcessed;
  final int notificationsCreated;
  final String? errorMessage;
  final DateTime runAt;
}
