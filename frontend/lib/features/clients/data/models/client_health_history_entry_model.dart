import '../../domain/entities/client_health_history_entry.dart';

class ClientHealthHistoryEntryModel extends ClientHealthHistoryEntry {
  const ClientHealthHistoryEntryModel({
    required super.id,
    required super.clientId,
    required super.previousStatus,
    required super.newStatus,
    required super.factors,
    required super.notes,
    required super.actorName,
    required super.createdAt,
  });

  factory ClientHealthHistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      ClientHealthHistoryEntryModel(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        previousStatus: json['previousStatus'] as String,
        newStatus: json['newStatus'] as String,
        factors: (json['factors'] as List<dynamic>).cast<String>(),
        notes: json['notes'] as String?,
        actorName: json['actorName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
