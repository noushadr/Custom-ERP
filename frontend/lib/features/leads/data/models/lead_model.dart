import '../../domain/entities/lead.dart';

class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.leadDate,
    required super.fullName,
    required super.companyName,
    required super.leadSource,
    required super.phone,
    required super.email,
    required super.country,
    required super.remarks,
    required super.serviceInterested,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) => LeadModel(
    id: json['id'] as String,
    leadDate: json['leadDate'] as String,
    fullName: json['fullName'] as String,
    companyName: json['companyName'] as String?,
    leadSource: json['leadSource'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    country: json['country'] as String?,
    remarks: json['remarks'] as String?,
    serviceInterested: json['serviceInterested'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
