import '../../domain/entities/leave_request.dart';

class LeaveRequestModel extends LeaveRequest {
  const LeaveRequestModel({
    required super.id,
    required super.employeeId,
    required super.requesterName,
    super.requesterPhotoUrl,
    required super.leaveTypeId,
    required super.leaveTypeName,
    required super.startDate,
    required super.endDate,
    required super.numberOfDays,
    required super.reason,
    required super.status,
    super.managerDecisionAt,
    super.managerDecisionByName,
    super.managerComment,
    super.hrDecisionAt,
    super.hrDecisionByName,
    super.hrComment,
    super.cancelledAt,
    required super.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) =>
      LeaveRequestModel(
        id: json['id'] as String,
        employeeId: json['employeeId'] as String,
        requesterName: json['requesterName'] as String,
        requesterPhotoUrl: json['requesterPhotoUrl'] as String?,
        leaveTypeId: json['leaveTypeId'] as String,
        leaveTypeName: json['leaveTypeName'] as String,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        numberOfDays: double.parse(json['numberOfDays'] as String),
        reason: json['reason'] as String,
        status: json['status'] as String,
        managerDecisionAt: json['managerDecisionAt'] == null
            ? null
            : DateTime.parse(json['managerDecisionAt'] as String),
        managerDecisionByName: json['managerDecisionByName'] as String?,
        managerComment: json['managerComment'] as String?,
        hrDecisionAt: json['hrDecisionAt'] == null
            ? null
            : DateTime.parse(json['hrDecisionAt'] as String),
        hrDecisionByName: json['hrDecisionByName'] as String?,
        hrComment: json['hrComment'] as String?,
        cancelledAt: json['cancelledAt'] == null
            ? null
            : DateTime.parse(json['cancelledAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
