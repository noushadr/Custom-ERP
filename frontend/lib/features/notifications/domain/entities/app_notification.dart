/// A persisted, per-user notification — named AppNotification rather than
/// Notification to avoid clashing with Flutter's own Notification class.
/// Currently created only by the Automations module.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.linkTarget,
    required this.linkEntityId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String message;

  /// Raw backend value: 'clients_projects' | 'tasks' | 'leave' | null.
  final String? linkTarget;
  final String? linkEntityId;
  final bool isRead;
  final DateTime createdAt;
}
