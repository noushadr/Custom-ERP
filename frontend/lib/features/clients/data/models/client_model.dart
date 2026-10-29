import '../../../../shared/utils/photo_url.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/project_refs.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.companyName,
    required super.industry,
    required super.website,
    required super.country,
    required super.address,
    required super.primaryContactName,
    required super.primaryContactEmail,
    required super.primaryContactPhone,
    required super.leadSource,
    required super.notes,
    super.accountManager,
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
    country: json['country'] as String?,
    address: json['address'] as String?,
    primaryContactName: json['primaryContactName'] as String?,
    primaryContactEmail: json['primaryContactEmail'] as String?,
    primaryContactPhone: json['primaryContactPhone'] as String?,
    leadSource: json['leadSource'] as String?,
    notes: json['notes'] as String?,
    accountManager: json['accountManager'] == null
        ? null
        : ProjectEmployeeRef(
            id:
                (json['accountManager'] as Map<String, dynamic>)['id']
                    as String,
            fullName:
                (json['accountManager'] as Map<String, dynamic>)['fullName']
                    as String,
            photoUrl: resolvePhotoUrl(
              (json['accountManager'] as Map<String, dynamic>)['photoUrl']
                  as String?,
            ),
          ),
    isArchived: json['isArchived'] as bool,
    healthStatus: json['healthStatus'] as String,
    healthFactors: (json['healthFactors'] as List<dynamic>).cast<String>(),
    healthNotes: json['healthNotes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
