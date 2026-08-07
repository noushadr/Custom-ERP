import '../../domain/entities/employee_request.dart';

class EmployeeRequestModel extends EmployeeRequest {
  const EmployeeRequestModel({
    required super.id,
    required super.requesterId,
    required super.requesterName,
    super.requesterPhotoUrl,
    required super.subject,
    required super.description,
    super.type,
    required super.status,
    super.managerDecisionAt,
    super.managerDecisionByName,
    super.hrDecisionAt,
    super.hrDecisionByName,
    super.rejectionReason,
    required super.createdAt,
  });

  factory EmployeeRequestModel.fromJson(Map<String, dynamic> json) =>
      EmployeeRequestModel(
        id: json['id'] as String,
        requesterId: json['requesterId'] as String,
        requesterName: json['requesterName'] as String,
        requesterPhotoUrl: json['requesterPhotoUrl'] as String?,
        subject: json['subject'] as String,
        description: json['description'] as String,
        type: json['type'] as String?,
        status: json['status'] as String,
        managerDecisionAt: json['managerDecisionAt'] == null
            ? null
            : DateTime.parse(json['managerDecisionAt'] as String),
        managerDecisionByName: json['managerDecisionByName'] as String?,
        hrDecisionAt: json['hrDecisionAt'] == null
            ? null
            : DateTime.parse(json['hrDecisionAt'] as String),
        hrDecisionByName: json['hrDecisionByName'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
