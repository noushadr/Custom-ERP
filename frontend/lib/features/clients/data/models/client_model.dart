import '../../domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.companyName,
    required super.industry,
    required super.website,
    required super.address,
    required super.primaryContactName,
    required super.primaryContactEmail,
    required super.primaryContactPhone,
    required super.notes,
    required super.isArchived,
    required super.healthStatus,
    required super.healthFactors,
    required super.healthNotes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
    id: json['id'] as String,
    companyName: json['companyName'] as String,
    industry: json['industry'] as String?,
    website: json['website'] as String?,
    address: json['address'] as String?,
    primaryContactName: json['primaryContactName'] as String?,
    primaryContactEmail: json['primaryContactEmail'] as String?,
    primaryContactPhone: json['primaryContactPhone'] as String?,
    notes: json['notes'] as String?,
    isArchived: json['isArchived'] as bool,
    healthStatus: json['healthStatus'] as String,
    healthFactors: (json['healthFactors'] as List<dynamic>).cast<String>(),
    healthNotes: json['healthNotes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
