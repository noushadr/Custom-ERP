/// A single health-status-change history entry — mirrors the backend's
/// ClientHealthHistory shape.
class ClientHealthHistoryEntry {
  const ClientHealthHistoryEntry({
    required this.id,
    required this.clientId,
    required this.previousStatus,
    required this.newStatus,
    required this.factors,
    required this.notes,
    required this.actorName,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String previousStatus;
  final String newStatus;
  final List<String> factors;
  final String? notes;
  final String actorName;
  final DateTime createdAt;
}
